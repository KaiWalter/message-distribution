#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $SCRIPT_DIR/Models/* ../funcdistributor/Models/
cp $SCRIPT_DIR/Models/* ../daprdistributor/
cp $SCRIPT_DIR/Models/* ../daprrecvexp/
cp $SCRIPT_DIR/Models/* ../daprrecvstd/