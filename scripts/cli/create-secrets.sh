#!/bin/bash

# feed Azure resource connection strings into local.settings.json for local Functions debugging
source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
STORAGE_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Storage/storageAccounts --query '[0].name' -o tsv`
SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
STORAGE_BLOB_CONNECTION=`az storage account show-connection-string -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME  --query connectionString -o tsv`
SERVICEBUS_CONNECTION=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE -n RootManageSharedAccessKey --query primaryConnectionString -o tsv`

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  '{STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc}' )

SOURCE_FOLDER="$(git rev-parse --show-toplevel)/src"

echo $JSON_STRING > $SOURCE_FOLDER/daprdistributor/secrets.json
echo $JSON_STRING > $SOURCE_FOLDER/daprreceiver/secrets.json
