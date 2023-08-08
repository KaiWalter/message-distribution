#!/bin/bash

while true
do
  scripts/cli/push-ingress.sh acafq
  scripts/cli/push-ingress.sh daprq
  scripts/cli/push-ingress.sh funcq
done

