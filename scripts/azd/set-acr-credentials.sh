#!/bin/bash

source <(azd env get-values)

ACRCREDS=`az acr credential show -n $AZURE_CONTAINER_REGISTRY_NAME`
ACRUSER=`echo $ACRCREDS | jq -r '.username'`
ACRPWD=`echo $ACRCREDS | jq -r '.passwords[0].value'`

if [[ $(az functionapp config appsettings list -n $AZURE_ENV_NAME$1 -g $RESOURCE_GROUP_NAME -o json | jq -r '.[] | select(.name | contains("DOCKER"))') == "" ]]; then

  az functionapp config appsettings set -n $AZURE_ENV_NAME$1 -g $RESOURCE_GROUP_NAME \
    --settings "DOCKER_REGISTRY_SERVER_URL=$AZURE_CONTAINER_REGISTRY_ENDPOINT" \
      "DOCKER_REGISTRY_SERVER_USERNAME=$ACRUSER" \
      "DOCKER_REGISTRY_SERVER_PASSWORD=$ACRPWD"

fi
