#!/bin/bash
source <(azd env get-values | sed 's/AZURE_/export AZURE_/g')