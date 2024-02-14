#!/bin/bash
# this file can be sourced to get major resource names^

source <(cat $(git rev-parse --show-toplevel)/.env)

export RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
export AZURE_CONTAINER_REGISTRY_NAME=`az resource list --tag azd-env-name=$AZURE_ENV_NAME --query "[?type=='Microsoft.ContainerRegistry/registries'].name" -o tsv`
export ACAENV_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.App/managedEnvironments --query "[0].name" -o tsv`
