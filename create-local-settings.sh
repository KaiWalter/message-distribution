#!/bin/bash

# feed Azure resource connection strings into local.settings.json for local Functions debugging

source <(azd env get-values)

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  '{IsEncrypted: false, Values:{FUNCTIONS_WORKER_RUNTIME: "DOTNET", AzureWebJobsStorage: "UseDevelopmentStorage=true", STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc }}' )

echo $JSON_STRING > src/test-data/local.settings.json
echo $JSON_STRING > src/func-distributor/local.settings.json
echo $JSON_STRING > src/func-recvexp/local.settings.json
echo $JSON_STRING > src/func-recvstd/local.settings.json