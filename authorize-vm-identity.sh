#!/bin/bash

source <(azd env get-values)
AZURE_VM_ID=`curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r '.compute.resourceId'`

if [ ! -z $AZURE_VM_ID ];
then
    AZURE_VM_MI_ID=`az vm show --id $AZURE_VM_ID --query 'identity.principalId' -o tsv`
fi

if [ ! -z $AZURE_VM_MI_ID ];
then
    az role assignment create --role Contributor --assignee $AZURE_VM_MI_ID --scope /subscriptions/$AZURE_SUBSCRIPTION_ID
fi
