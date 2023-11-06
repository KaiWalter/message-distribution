#!/bin/bash

set -e

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments"
  exit 2
elif [ $# -gt 1 ]; then
  echo 1>&2 "$0: too many arguments"
  exit 2
fi

source <(cat $(git rev-parse --show-toplevel)/.env)

TESTNAME=${1^^}
TESTNAMEL=${1,,}
TESTPREFIX=${TESTNAME:0:4}
TESTPREFIXL=${TESTNAMEL:0:4}
RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
APPINSIGHTS_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Insights/components --query '[0].name' -o tsv`
STORAGE_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Storage/storageAccounts --query '[0].name' -o tsv`
STORAGE_BLOB_CONNECTION=`az storage account show-connection-string -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME  --query connectionString -o tsv`
TESTDATA_NAME=`az resource list --tag azd-service-name=testdata --query "[?resourceGroup=='$RESOURCE_GROUP_NAME'].name" -o tsv`
TESTDATA_URI=https://$(az containerapp show -g $RESOURCE_GROUP_NAME -n $TESTDATA_NAME --query properties.configuration.ingress.fqdn -o tsv)

containers=(express-outbox standard-outbox)
for c in "${containers[@]}"
do
  az storage blob delete-batch --source $c \
    --account-name $STORAGE_NAME \
    --connection-string $STORAGE_BLOB_CONNECTION
done

# ---- initiate test and extract schedule timestamp and amount of messages from response
PUSHRESPONSE=`curl -s -X POST -d '{}' "$TESTDATA_URI/api/PushIngress$TESTNAME"`
SCHEDULE=`echo $PUSHRESPONSE | jq -r '.scheduledTimestamp'`
TARGET_COUNT=`echo $PUSHRESPONSE | jq -r '.count'`

echo $SCHEDULE $TESTNAME $COUNT

current_epoch=$(date +%s)
target_epoch=$(date -d $SCHEDULE +%s)

if [ $target_epoch -gt $current_epoch ]; then

  sleep_seconds=$(( $target_epoch - $current_epoch ))

  sleep $sleep_seconds
fi

# ---- wait until all scheduled messages have been written to blob
ACTUAL_COUNT=0

until [ $ACTUAL_COUNT -eq $TARGET_COUNT ]
do
  ACTUAL_COUNT=0

  for c in "${containers[@]}"
  do
    blob_count=`az storage blob list -c $c --num-results $TARGET_COUNT \
      --account-name $STORAGE_NAME --connection-string $STORAGE_BLOB_CONNECTION --query "length(@)" -o tsv`

    ACTUAL_COUNT=$(($ACTUAL_COUNT+$blob_count))
  done

  echo $ACTUAL_COUNT of $TARGET_COUNT

  if [ $ACTUAL_COUNT -lt $TARGET_COUNT ]; then sleep 10; fi
done

# ---- detect when last blob has been written
LAST_WRITE=${SCHEDULE:0:19}

for c in "${containers[@]}"
do
  last=`az storage blob list -c $c --num-results $TARGET_COUNT \
    --account-name $STORAGE_NAME --connection-string $STORAGE_BLOB_CONNECTION --query "[].properties.lastModified | reverse(sort(@))[0]" -o tsv`
  last=${last:0:19}

  if [ "$last" \> "$LAST_WRITE" ]; then
    LAST_WRITE=$last
  fi
done

# ---- calculate timespan from schedule to blob last written
schedule_epoch=$(date -d $SCHEDULE +%s)
last_write_epoch=$(date -d $LAST_WRITE +%s)
runtime_seconds=$(( $last_write_epoch - $schedule_epoch ))

echo "$SCHEDULE | $TESTNAME | $TARGET_COUNT | $runtime_seconds" >> LOG.md
