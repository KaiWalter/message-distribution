#!/bin/bash

source <(azd env get-values)

curl -v -X POST -d '{}' "$TESTDATA_URI/api/PushIngress$1"