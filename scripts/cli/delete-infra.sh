#!/bin/bash
source <(cat $(git rev-parse --show-toplevel)/.env)

rg=`az group list  --query "[?starts_with(name,'$AZURE_ENV_NAME')].name" -o tsv`

az group delete -n $rg
