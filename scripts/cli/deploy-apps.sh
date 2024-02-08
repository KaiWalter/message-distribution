#!/bin/bash

set -e

source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
AZURE_CONTAINER_REGISTRY_NAME=`az resource list --tag azd-env-name=$AZURE_ENV_NAME --query "[?type=='Microsoft.ContainerRegistry/registries'].name" -o tsv`

until [ ! -z $AZURE_CONTAINER_REGISTRY_NAME ];
do
  echo "wait 30 seconds for resources & AAD auth to be available"
  sleep 30
  AZURE_CONTAINER_REGISTRY_NAME=`az resource list --tag azd-env-name=$AZURE_ENV_NAME --query "[?type=='Microsoft.ContainerRegistry/registries'].name" -o tsv`
done

AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`
AZURE_CONTAINER_REGISTRY_ACRPULL_ID=`az identity list -g $RESOURCE_GROUP_NAME --query "[?ends_with(name,'acrpull')].id" -o tsv`
AZURE_KEY_VAULT_SERVICE_GET_ID=`az identity list -g $RESOURCE_GROUP_NAME --query "[?ends_with(name,'kv-get')].id" -o tsv`

REVISION=`date +"%s"`

apps=($(for d in src/* ; do echo ${d##*/}; done))

for app in "${apps[@]}"
do
  echo "$app"

  if [ "$1" == "build" ];
  then
    IMAGE=$app:$REVISION
    az acr build --registry $AZURE_CONTAINER_REGISTRY_NAME --image $IMAGE src/$app/
  else
    TAG=`az acr repository show-tags -n $AZURE_CONTAINER_REGISTRY_NAME --repository $app --top 1 --orderby time_desc -o tsv`
    IMAGE=$app:$TAG
  fi

  echo "$AZURE_CONTAINER_REGISTRY_ENDPOINT/$IMAGE"

  declare IMAGE_$app=$AZURE_CONTAINER_REGISTRY_ENDPOINT/$IMAGE
done

az deployment sub create -f infra/main.bicep -n main-apps-$REVISION \
  -l $AZURE_LOCATION \
  -p environmentName=$AZURE_ENV_NAME \
  location=$AZURE_LOCATION \
  daprDistributorImageName=$IMAGE_daprdistributor \
  daprReceiverImageName=$IMAGE_daprreceiver \
  funcDistributorImageName=$IMAGE_funcdistributor \
  funcReceiverImageName=$IMAGE_funcreceiver \
  testdataImageName=$IMAGE_testdata

