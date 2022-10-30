#!/bin/bash

# feed Azure resource connection strings into local.settings.json for local Functions debugging

source <(azd env get-values)

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  '{IsEncrypted: false, Values:{FUNCTIONS_WORKER_RUNTIME: "DOTNET", AzureWebJobsStorage: "UseDevelopmentStorage=true", STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc }}' )

echo $JSON_STRING > src/testdata/local.settings.json
echo $JSON_STRING > src/funcdistributor/local.settings.json
echo $JSON_STRING > src/funcrecvexp/local.settings.json
echo $JSON_STRING > src/funcrecvstd/local.settings.json

JSON_STRING=$( jq -n \
                  --arg aic "$APPINSIGHTS_CONNECTION_STRING" \
                  '{Logging: {LogLevel: {Default: "Information", "Microsoft.AspNetCore": "Information" }},ApplicationInsights:{ConnectionString: $aic, EnableAdaptiveSampling:false,EnablePerformanceCounterCollectionModule:false}}' )

echo $JSON_STRING > src/daprdistributor/appsettings.Development.json
echo $JSON_STRING > src/daprrecvexp/appsettings.Development.json
echo $JSON_STRING > src/daprrecvstd/appsettings.Development.json

JSON_STRING=$( jq -n \
                  '{Logging: {LogLevel: {Default: "Warning", "Microsoft.AspNetCore": "Information" }},ApplicationInsights:{EnableAdaptiveSampling:false,EnablePerformanceCounterCollectionModule:false}}' )

echo $JSON_STRING > src/daprdistributor/appsettings.json
echo $JSON_STRING > src/daprrecvexp/appsettings.json
echo $JSON_STRING > src/daprrecvstd/appsettings.json
