#!/bin/bash

source <(azd env get-values)

query="requests | where cloud_RoleName startswith 'func' | where name != 'Health' | where timestamp > todatetime('2022-11-03T07:09:26.9394443Z') | where success == true | summarize count(),sum(duration),min(timestamp),max(timestamp) | extend runtimeMs=datetime_diff('millisecond', max_timestamp, min_timestamp)"
echo $query
az monitor app-insights query --app $APPINSIGHTS_NAME -g $RESOURCE_GROUP_NAME --analytics-query "$query" --debug
