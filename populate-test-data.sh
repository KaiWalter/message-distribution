#!/bin/bash

source <(azd env get-values)

curl -X POST "$TESTDATA_URI/api/Generate"