#!/bin/bash
#
set -e

ORDERID=0

function generate_message()
{
  UUID=`uuidgen`
  if [[ $((ORDERID % 2)) -eq 0 ]]; then 
    DELIVERY=Express
  else 
    DELIVERY=Standard
  fi
  jq -c -n \
        --arg uuid "$UUID" \
        --arg orderid "$ORDERID" \
        --arg delivery "$DELIVERY" \
        '{OrderId: $orderid|tonumber, OrderGuid: $uuid, Delivery: $delivery}'
}

ORDERID=$((ORDERID + 1))
dapr publish --publish-app-id distributor \
  --topic q-order-ingress-dapr \
  --pubsub order-pubsub \
  --data "$(generate_message)" \
  --metadata '{"rawPayload":"true"}'

ORDERID=$((ORDERID + 1))
dapr publish --publish-app-id distributor \
  --topic q-order-ingress-dapr \
  --pubsub order-pubsub \
  --data "$(generate_message)" \
  --metadata '{"rawPayload":"true"}'
#
