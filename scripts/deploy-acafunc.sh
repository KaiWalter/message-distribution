#!/bin/bash
source <(azd env get-values)

REVISION=`date +"%s"`

declare -a apps=("acafdistributor" "acafrecvexp" "acafrecvstd")

if [ "$1" == "recreate" ];
then
    for app in "${apps[@]}"
    do
            az functionapp delete -n $app -g $RESOURCE_GROUP_NAME
    done
fi

read -p "wait for deletion" -n1 -s

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


    if [ ! `az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Web/sites --query "[?contains(name,'$app')].id" -o tsv` ];
    then
        az functionapp create -g $RESOURCE_GROUP_NAME --name $app \
        --environment $ENVIRONMENT_NAME \
        --functions-version 4 \
        --runtime dotnet-isolated \
        --storage-account $STORAGE_NAME \
        --app-insights $APPINSIGHTS_NAME \
        --app-insights-key $APPINSIGHTS_INSTRUMENTATIONKEY \
        --image $AZURE_CONTAINER_REGISTRY_ENDPOINT/$IMAGE
    else
        az functionapp config container set --image $AZURE_CONTAINER_REGISTRY_ENDPOINT/$IMAGE --name $app --resource-group $RESOURCE_GROUP_NAME
    fi

done
