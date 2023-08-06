#!/bin/bash

# feed Azure resource connection strings into secrets.json for local Dapr debugging

source <(azd env get-values)

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stc "$STORAGE_BLOB_CONNECTION" \
                  '{STORAGE_CONNECTION: $stc,SERVICEBUS_CONNECTION: $sbc}' )

SOURCE_FOLDER="$(git rev-parse --show-toplevel)/src"

echo $JSON_STRING > $SOURCE_FOLDER/daprdistributor/secrets.json
echo $JSON_STRING > $SOURCE_FOLDER/daprrecvexp/secrets.json
echo $JSON_STRING > $SOURCE_FOLDER/daprrecvstd/secrets.json
