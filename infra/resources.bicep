param name string
param location string
param principalId string = ''
param resourceToken string
param tags object

module containerAppsResources './containerapps.bicep' = {
  name: 'containerapps-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
  }

  dependsOn: [
    serviceBusResources
    logAnalyticsResources
  ]
}

module keyVaultResources './keyvault.bicep' = {
  name: 'keyvault-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
    principalId: principalId
  }
}

module serviceBusResources './servicebus.bicep' = {
  name: 'sb-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
    skuName: 'Standard'
  }
}

module appInsightsResources './appinsights.bicep' = {
  name: 'appinsights-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
  }
}

module logAnalyticsResources './loganalytics.bicep' = {
  name: 'loganalytics-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
  }
}

output SERVICEBUS_ENDPONT string = serviceBusResources.outputs.SERVICEBUS_ENDPOINT
output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_NAME
