#!/bin/bash
source <(azd env get-values)
REVISION=`date +"%s"`
APP_NAME=azurefunctionsimage
RESOURCE_GROUP_NAME=kw-messdist-rg
ENVIRONMENT_NAME=cae-ggnx3xbeyyqzy
STORAGE_NAME=stggnx3xbeyyqzy
APPINSIGHTS_NAME=appi-ggnx3xbeyyqzy
APPINSIGHTS_INSTRUMENTATIONKEY=1727d262-4c78-4811-9fbb-05a4437bcf15

IMAGE=ancientitguy/$APP_NAME:latest

if [ "$1" == "build" ];
then
    docker build -t $IMAGE . 
    docker push $IMAGE
fi

az deployment group create -g kw-messdist-rg -n acafunc$REVISION -f ./ACAFunc.bicep

# az functionapp create -g $RESOURCE_GROUP_NAME --name $APP_NAME \
#     --environment $ENVIRONMENT_NAME \
#     --functions-version 4 \
#     --runtime dotnet-isolated \
#     --storage-account $STORAGE_NAME \
#     --app-insights $APPINSIGHTS_NAME \
#     --app-insights-key $APPINSIGHTS_INSTRUMENTATIONKEY \
#     --image $IMAGE --debug


# if [ "$1" == "build" ];
# then
#     az acr build --registry $AZURE_CONTAINER_REGISTRY_NAME --image $IMAGE .
#     IMAGE=$APP_NAME:$REVISION
# else
#     TAG=`az acr repository show-tags -n $AZURE_CONTAINER_REGISTRY_NAME --repository $APP_NAME --top 1 --orderby time_desc -o tsv`
#     IMAGE=$APP_NAME:$TAG
# fi

# if [ ! `az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Web/sites --query "[?contains(name,'$APP_NAME')].id" -o tsv` ];
# then
    # az functionapp create -g $RESOURCE_GROUP_NAME --name $APP_NAME \
    # --environment $ENVIRONMENT_NAME \
    # --functions-version 4 \
    # --runtime dotnet-isolated \
    # --storage-account $STORAGE_NAME \
    # --app-insights $APPINSIGHTS_NAME \
    # --app-insights-key $APPINSIGHTS_INSTRUMENTATIONKEY \
    # --image $AZURE_CONTAINER_REGISTRY_ENDPOINT/$IMAGE
# else
#     az functionapp config container set --image $AZURE_CONTAINER_REGISTRY_ENDPOINT/$IMAGE --name $APP_NAME --resource-group $RESOURCE_GROUP_NAME
# fi

