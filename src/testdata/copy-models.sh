#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../acafdistributor/Models/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../acafrecvexp/Models/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../acafrecvstd/Models/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../funcdistributor/Models/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../funcrecvexp/Models/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../funcrecvstd/Models/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../daprdistributor/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../daprrecvexp/
cp $SCRIPT_DIR/Models/* $SCRIPT_DIR/../daprrecvstd/
