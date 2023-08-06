#!/bin/bash
source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
TESTDATA_NAME=`az resource list --tag azd-service-name=testdata --query "[?resourceGroup=='$RESOURCE_GROUP_NAME'].name" -o tsv`
TESTDATA_URI=https://$(az containerapp show -g $RESOURCE_GROUP_NAME -n $TESTDATA_NAME --query properties.configuration.ingress.fqdn -o tsv)

curl -v -X POST -d '{}' "$TESTDATA_URI/api/PushIngress$1"
