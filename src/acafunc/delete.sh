#!/bin/bash
source <(azd env get-values)
APP_NAME=acafunc

az functionapp delete -n $APP_NAME -g $RESOURCE_GROUP_NAME
