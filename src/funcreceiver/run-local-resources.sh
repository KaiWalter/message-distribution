#!/bin/bash

LOCALPORT=7071

did=$(docker ps --filter name=azurerite --format '{{.ID}}')
if [ -z "${did}" ]; then
  did=`docker run -d --name azurerite -p 10000:10000 -p 10001:10001 -p 10002:10002 \
     mcr.microsoft.com/azure-storage/azurite`
fi
echo "azureite running in docker with ID $did"

func start -p $LOCALPORT
