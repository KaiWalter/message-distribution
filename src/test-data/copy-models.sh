#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $SCRIPT_DIR/Models/* ../func-distributor/Models/
cp $SCRIPT_DIR/Models/* ../dapr-distributor/
cp $SCRIPT_DIR/Models/* ../dapr-recvexp/
cp $SCRIPT_DIR/Models/* ../dapr-recvstd/