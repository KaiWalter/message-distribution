#!/bin/bash

# feed Azure resource connection strings into local.settings.json for local Functions debugging
source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`

SOURCE_FOLDER="$(git rev-parse --show-toplevel)/src"

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  '{IsEncrypted: false, Values:{FUNCTIONS_WORKER_RUNTIME: "DOTNET", AzureWebJobsStorage: "UseDevelopmentStorage=true", STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc }}' )

echo $JSON_STRING > $SOURCE_FOLDER/testdata/local.settings.json
echo $JSON_STRING > $SOURCE_FOLDER/funcdistributor/local.settings.json
echo $JSON_STRING > $SOURCE_FOLDER/funcrecvexp/local.settings.json
echo $JSON_STRING > $SOURCE_FOLDER/funcrecvstd/local.settings.json

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  '{IsEncrypted: false, Values:{FUNCTIONS_WORKER_RUNTIME: "dotnet-isolated", AzureWebJobsStorage: "UseDevelopmentStorage=true", STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc }}' )

echo $JSON_STRING > $SOURCE_FOLDER/acafdistributor/local.settings.json
echo $JSON_STRING > $SOURCE_FOLDER/acafrecvexp/local.settings.json
echo $JSON_STRING > $SOURCE_FOLDER/acafrecvstd/local.settings.json

JSON_STRING=$( jq -n \
                  --arg aic "$APPINSIGHTS_CONNECTION_STRING" \
                  '{Logging: {LogLevel: {Default: "Information", "Microsoft.AspNetCore": "Information" }},ApplicationInsights:{ConnectionString: $aic, EnableAdaptiveSampling:false,EnablePerformanceCounterCollectionModule:false}}' )

echo $JSON_STRING > $SOURCE_FOLDER/daprdistributor/appsettings.Development.json
echo $JSON_STRING > $SOURCE_FOLDER/daprrecvexp/appsettings.Development.json
echo $JSON_STRING > $SOURCE_FOLDER/daprrecvstd/appsettings.Development.json

JSON_STRING=$( jq -n \
                  '{Logging: {LogLevel: {Default: "Warning", "Microsoft.AspNetCore": "Information" }},ApplicationInsights:{EnableAdaptiveSampling:false,EnablePerformanceCounterCollectionModule:false}}' )

echo $JSON_STRING > $SOURCE_FOLDER/daprdistributor/appsettings.json
echo $JSON_STRING > $SOURCE_FOLDER/daprrecvexp/appsettings.json
echo $JSON_STRING > $SOURCE_FOLDER/daprrecvstd/appsettings.json
