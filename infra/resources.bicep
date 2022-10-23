param name string
param location string
param principalId string = ''
param resourceToken string
param testdataImageName string = ''
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

module storageResources 'storage.bicep' = {
  name: 'st-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
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

module testdataResources './testdata.bicep' = {
  name: 'testdata-resources'
  params: {
    name: name
    location: location
    imageName: testdataImageName != '' ? testdataImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

output SERVICEBUS_CONNECTION string = serviceBusResources.outputs.SERVICEBUS_CONNECTION
output STORAGE_BLOB_CONNECTION string = storageResources.outputs.STORAGE_BLOB_CONNECTION
output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_NAME
