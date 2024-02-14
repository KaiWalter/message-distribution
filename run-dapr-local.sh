#!/bin/bash

set -e

find . -name .dapr -type d -exec rm -r {} \;

[[ "$1" == "delete-cloud" ]] &&  az containerapp delete --ids $(az containerapp list -o tsv --query "[?contains(name, 'dapr')].id")

dapr run -f dapr-multi-run.yml
