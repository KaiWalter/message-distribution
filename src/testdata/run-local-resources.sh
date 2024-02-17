#!/bin/bash

LOCALPORT=7072

did=$(docker ps --filter name=azurerite --format '{{.ID}}')
if [ -z "${did}" ]; then
  did=`docker run -d --name azurerite -p 10000:10000 -p 10001:10001 -p 10002:10002 \
     mcr.microsoft.com/azure-storage/azurite`
fi
echo "azureite running in docker with ID $did"

func start -p $LOCALPORT &
pid=$!

sleep 10

until curl -s -f -o /dev/null "http://localhost:$LOCALPORT/api/Health"
do
  sleep 5
done

echo -e '\n\nReady for testing...'

curl -d '{"Count":5}' http://localhost:$LOCALPORT/api/Generate

trap 'continue' SIGINT
while [[ -z "$ABORT" ]]
do
  read -p "`echo -e '\n\npress enter to send test (some input to abort)'`" ABORT
  curl -d '{}' http://localhost:$LOCALPORT/api/PushIngressFuncQ
done

kill $pid
