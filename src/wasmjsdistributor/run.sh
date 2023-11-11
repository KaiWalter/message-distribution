#!/bin/bash

# feed Azure resource connection strings into local.settings.json for local Functions debugging
source <(cat $(git rev-parse --show-toplevel)/.env)

RESOURCE_GROUP_NAME=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`
export AZURE_SERVICE_BUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
export AZURE_POLICY_NAME=RootManageSharedAccessKey
export AZURE_POLICY_KEY=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $AZURE_SERVICE_BUS_NAMESPACE -n $AZURE_POLICY_NAME --query primaryKey -o tsv`
slight -c azsbus_slightfile.toml run main.wasm -l
