#!/bin/bash
AZURE_ENV_NAME="kw-messdist"
AZURE_LOCATION="westeurope"

REVISION=`date +"%s"`

az deployment sub create -f infra/main.bicep -n main-infra-$REVISION \
  -l $AZURE_LOCATION \
  -p name=$AZURE_ENV_NAME \
  location=$AZURE_LOCATION
