#!/bin/bash

while true
do
  scripts/cli/push-ingress.sh acafq
  scripts/cli/push-ingress.sh funcq
  scripts/cli/push-ingress.sh daprq
done

