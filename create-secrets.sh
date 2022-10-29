#!/bin/bash

# feed Azure resource connection strings into secrets.json for local Dapr debugging

source <(azd env get-values)

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  '{STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc}' )

echo $JSON_STRING > src/daprdistributor/secrets.json
echo $JSON_STRING > src/daprrecvexp/secrets.json
echo $JSON_STRING > src/daprrecvstd/secrets.json
