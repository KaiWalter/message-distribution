#!/bin/bash

set -e

if [ $# -lt 3 ]; then
  echo 1>&2 "$0: not enough arguments"
  exit 2
elif [ $# -gt 3 ]; then
  echo 1>&2 "$0: too many arguments"
  exit 2
fi

source <(cat $(git rev-parse --show-toplevel)/.env)

DAPR_API_TOKEN=$1
DAPR_GRPC_ENDPOINT=$2
DAPR_PORT=$3

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
DCRADISTRIBUTOR_NAME=`az resource list --tag azd-service-name=dcradistributor --query "[?resourceGroup=='$RESOURCE_GROUP_NAME'].name" -o tsv`
ACA_ENV=`az containerapp env list -g $RESOURCE_GROUP_NAME --query '[0].name' -o tsv`

az containerapp update \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DCRADISTRIBUTOR_NAME \
  --environment $ACA_ENV \
  --secrets "DAPR_API_TOKEN=$DAPR_API_TOKEN" \
  "DAPR_GRPC_ENDPOINT=$DAPR_GRPC_ENDPOINT" \
  "DAPR_PORT=$DAPR_PORT"
