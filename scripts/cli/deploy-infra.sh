#!/bin/bash
source <(cat $(git rev-parse --show-toplevel)/.env)

REVISION=`date +"%s"`

az deployment sub create -f infra/main.bicep -n main-infra-$REVISION \
  -l $AZURE_LOCATION \
  -p environmentName=$AZURE_ENV_NAME \
  daprComponentsModel=$DAPR_COMPONENTS_MODEL \

# remove Dapr components marked with scope  "skip"
ACAENV_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.App/managedEnvironments --query "[0].name" -o tsv`
az containerapp env dapr-component list -g $RESOURCE_GROUP_NAME -n $ACAENV_NAME \
  --query "[?properties.scopes[0]=='skip'].name" -o tsv | \
  xargs -n1 az containerapp env dapr-component remove -g $RESOURCE_GROUP_NAME -n $ACAENV_NAME --dapr-component-name

  location=$AZURE_LOCATION
