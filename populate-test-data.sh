#!/bin/bash

source <(azd env get-values)

curl -X POST -d '{"Count":1000}' "$TESTDATA_URI/api/Generate"