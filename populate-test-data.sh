#!/bin/bash

source <(azd env get-values)

curl -X POST -d '{"Count":10000}' "$TESTDATA_URI/api/Generate"