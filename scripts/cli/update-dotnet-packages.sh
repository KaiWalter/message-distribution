#!/bin/bash
cat $1 | grep PackageReference | sed -e 's/.*<PackageReference Include="\(.*\)" Version.*/dotnet add package \1/'  | sh;

