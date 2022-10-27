#!/bin/bash

for dir in ./*/     
do
    echo "${dir##*/}"
    pushd $dir
    rm -rf bin
    rm -rf obj
    dotnet build
    popd
    dir=${dir%*/}      # remove the trailing "/"
done