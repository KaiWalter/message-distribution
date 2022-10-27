#!/bin/bash

APP_PORT=5000
ASPNETCORE_URLS="http://localhost:$APP_PORT"

dapr run --app-id daprdistributor \
    --app-port ${APP_PORT} \
    --enable-app-health-check \
    --app-health-probe-interval 60 \
    --components-path ./components/ \
    --config ./components/config.yaml \
    --log-level debug \
    -- dotnet run --urls ${ASPNETCORE_URLS}