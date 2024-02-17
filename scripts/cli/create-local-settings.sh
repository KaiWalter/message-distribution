#!/bin/bash

# feed Azure resource connection strings into local.settings.json for local Functions debugging
source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
APPINSIGHTS_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Insights/components --query '[0].name' -o tsv`
STORAGE_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Storage/storageAccounts --query '[0].name' -o tsv`
SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
APPINSIGHTS_CONNECTION_STRING=`az monitor app-insights component show -g $RESOURCE_GROUP_NAME -a $APPINSIGHTS_NAME --query connectionString -o tsv`
APPINSIGHTS_INSTRUMENTATION_KEY=`az monitor app-insights component show -g $RESOURCE_GROUP_NAME -a $APPINSIGHTS_NAME --query instrumentationKey -o tsv`
STORAGE_BLOB_CONNECTION=`az storage account show-connection-string -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME  --query connectionString -o tsv`
SERVICEBUS_CONNECTION=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE -n RootManageSharedAccessKey --query primaryConnectionString -o tsv`
SOURCE_FOLDER="$(git rev-parse --show-toplevel)/src"

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  --arg aik "$APPINSIGHTS_INSTRUMENTATION_KEY" \
                  '{IsEncrypted: false, Values:{FUNCTIONS_WORKER_RUNTIME: "dotnet", AzureWebJobsStorage: "UseDevelopmentStorage=true", STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc, APPINSIGHTS_INSTRUMENTATIONKEY: $aik }}' )

echo $JSON_STRING > $SOURCE_FOLDER/testdata/local.settings.json

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  --arg aik "$APPINSIGHTS_INSTRUMENTATION_KEY" \
                  '{IsEncrypted: false, Values:{FUNCTIONS_WORKER_RUNTIME: "dotnet-isolated", AzureWebJobsStorage: "UseDevelopmentStorage=true", STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc, APPINSIGHTS_INSTRUMENTATIONKEY: $aik, QUEUE_NAME_INGRESS: "q-order-ingress-func", QUEUE_NAME_EXPRESS: "q-order-express-func", QUEUE_NAME_STANDARD: "q-order-standard-func" }}' ) 
echo $JSON_STRING > $SOURCE_FOLDER/funcdistributor/local.settings.json
JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  --arg aik "$APPINSIGHTS_INSTRUMENTATION_KEY" \
                  '{IsEncrypted: false, Values:{FUNCTIONS_WORKER_RUNTIME: "dotnet-isolated", AzureWebJobsStorage: "UseDevelopmentStorage=true", STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc, APPINSIGHTS_INSTRUMENTATIONKEY: $aik, QUEUE_NAME_INGRESS: "q-order-ingress-func", QUEUE_NAME_EXPRESS: "q-order-express-func", QUEUE_NAME_STANDARD: "q-order-standard-func", INSTANCE: "express" }}' ) 
echo $JSON_STRING > $SOURCE_FOLDER/funcreceiver/local.settings.json

JSON_STRING=$( jq -n \
                  --arg aic "$APPINSIGHTS_CONNECTION_STRING" \
                  '{Logging: {LogLevel: {Default: "Information", "Microsoft.AspNetCore": "Warning" }, ApplicationInsights: {LogLevel: {Default: "Information"}}},ApplicationInsights:{ConnectionString: $aic, EnableAdaptiveSampling:false,EnablePerformanceCounterCollectionModule:false}}' )

echo $JSON_STRING > $SOURCE_FOLDER/daprdistributor/appsettings.Development.json
echo $JSON_STRING > $SOURCE_FOLDER/daprreceiver/appsettings.Development.json

JSON_STRING=$( jq -n \
                  '{Logging: {LogLevel: {Default: "Warning", "Microsoft.AspNetCore": "Warning" }, ApplicationInsights: {LogLevel: {Default: "Information"}}},ApplicationInsights:{EnableAdaptiveSampling:false,EnablePerformanceCounterCollectionModule:false}}' )

echo $JSON_STRING > $SOURCE_FOLDER/daprdistributor/appsettings.json
echo $JSON_STRING > $SOURCE_FOLDER/daprreceiver/appsettings.json
