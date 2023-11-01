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
TESTDATA_NAME=`az resource list --tag azd-service-name=testdata --query "[?resourceGroup=='$RESOURCE_GROUP_NAME'].name" -o tsv`
TESTDATA_URI=https://$(az containerapp show -g $RESOURCE_GROUP_NAME -n $TESTDATA_NAME --query properties.configuration.ingress.fqdn -o tsv)

PUSHRESPONSE=`curl -s -X POST -d '{}' "$TESTDATA_URI/api/PushIngress$TESTNAME"`
echo response: $PUSHRESPONSE
SCHEDULE=`echo $PUSHRESPONSE | jq -r '.scheduledTimestamp'`
COUNT=`echo $PUSHRESPONSE | jq -r '.count'`
echo sch/test/c: $SCHEDULE $TESTNAME $COUNT

current_epoch=$(date +%s)
target_epoch=$(date -d $SCHEDULE +%s)

if [ $target_epoch -gt $current_epoch ]; then

  sleep_seconds=$(( $target_epoch - $current_epoch ))

  sleep $sleep_seconds
fi

sleep 180

query="requests | where cloud_RoleName matches regex '($TESTPREFIX|$TESTPREFIXL)(dist|recv)' | where name != 'Health' and name !startswith 'GET' | where timestamp > todatetime('$SCHEDULE') | where success == true | summarize count(),sum(duration),min(timestamp),max(timestamp) | project count_, runtimeMs=datetime_diff('millisecond', max_timestamp, min_timestamp)"
result=`az monitor app-insights query --app $APPINSIGHTS_NAME -g $RESOURCE_GROUP_NAME --analytics-query "$query"`
first_column=`echo $result | jq -r '.tables[0].columns[0].name'`
if [ $first_column == 'count_' ];
then
  count=`echo $result | jq -r '.tables[0].rows[0][0]'`
  runtime=`echo $result | jq -r '.tables[0].rows[0][1]'`
else
  count=`echo $result | jq -r '.tables[0].rows[0][1]'`
  runtime=`echo $result | jq -r '.tables[0].rows[0][0]'`
fi

echo "$SCHEDULE | $TESTNAME | $count | $runtime" >> LOG.md
