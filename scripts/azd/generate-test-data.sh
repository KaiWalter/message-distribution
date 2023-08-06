#!/bin/bash

source <(azd env get-values)

if [ -z "$1" ]
then
    i=10000
else
    i=$1
fi

JSON_STRING=$( jq -n \
                  --argjson i "$i" \
                  '{Count: $i}' )

echo $JSON_STRING $TESTDATA_URI/api/Generate

curl -X POST -d "$JSON_STRING" "$TESTDATA_URI/api/Generate"