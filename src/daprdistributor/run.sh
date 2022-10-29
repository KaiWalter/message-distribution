#!/bin/bash

APP_ID=daprdistributor
APP_PORT=5000
DAPR_HTTP_PORT=3500
ASPNETCORE_URLS="http://localhost:$APP_PORT"

dapr run --app-id ${APP_ID} \
    --app-port ${APP_PORT} \
    --dapr-http-port ${DAPR_HTTP_PORT} \
    --enable-app-health-check \
    --app-health-probe-interval 60 \
    --components-path ./components/ \
    --config ./components/config.yaml \
    --log-level debug \
    -- dotnet run --urls ${ASPNETCORE_URLS}