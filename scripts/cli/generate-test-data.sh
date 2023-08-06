#!/bin/bash
source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
TESTDATA_NAME=`az resource list --tag azd-service-name=testdata --query "[?resourceGroup=='$RESOURCE_GROUP_NAME'].name" -o tsv`
TESTDATA_URI=https://$(az containerapp show -g $RESOURCE_GROUP_NAME -n $TESTDATA_NAME --query properties.configuration.ingress.fqdn -o tsv)

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
