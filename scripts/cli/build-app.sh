#!/bin/bash
source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
AZURE_CONTAINER_REGISTRY_NAME=`az resource list --tag azd-env-name=$AZURE_ENV_NAME --query "[?type=='Microsoft.ContainerRegistry/registries'].name" -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`
AZURE_CONTAINER_REGISTRY_ACRPULL_ID=`az identity list -g $RESOURCE_GROUP_NAME --query "[?ends_with(name,'acrpull')].id" -o tsv`
AZURE_KEY_VAULT_SERVICE_GET_ID=`az identity list -g $RESOURCE_GROUP_NAME --query "[?ends_with(name,'kv-get')].id" -o tsv`

REVISION=`date +"%s"`

az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

apps=($1)

for app in "${apps[@]}"
do
  echo "$app"

  # IMAGE=$app:$REVISION
  # az acr build --registry $AZURE_CONTAINER_REGISTRY_NAME --image $IMAGE src/$app/
  # declare IMAGE_$app=$AZURE_CONTAINER_REGISTRY_ENDPOINT/$IMAGE
  IMAGE=$AZURE_CONTAINER_REGISTRY_ENDPOINT/$app:$REVISION
  docker build --push -t $IMAGE src/$app/ 
  declare IMAGE_$app=$IMAGE
done

