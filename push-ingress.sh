#!/bin/bash

source <(azd env get-values)

curl -X POST -d '{}' "$TESTDATA_URI/api/PushIngress"