param name string
param location string
param principalId string = ''
param resourceToken string
param tags object

param testdataImageName string = ''
param funcDistImageName string = ''
param funcRecvExpImageName string = ''
param funcRecvStdImageName string = ''
param daprDistImageName string = ''
param daprRecvExpImageName string = ''
param daprRecvStdImageName string = ''

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
    appInsightsResources
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
    loganalytics_workspace_id: logAnalyticsResources.outputs.LOGANALYTICS_WORKSPACE_ID
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
    envName: name
    appName: 'testdata'
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

module funcDistResources './funcdistributor.bicep' = {
  name: 'funcdist-resources'
  params: {
    envName: name
    appName: 'funcdistributor'
    entityNameForScaling: 'order-ingress-func'
    location: location
    imageName: funcDistImageName != '' ? funcDistImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module funcRecvExpResources './funcrecvexp.bicep' = {
  name: 'funcrecvexp-resources'
  params: {
    envName: name
    appName: 'funcrecvexp'
    entityNameForScaling: 'order-express-func'
    location: location
    imageName: funcRecvExpImageName != '' ? funcRecvExpImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module funcRecvStdResources './funcrecvstd.bicep' = {
  name: 'funcrecvstd-resources'
  params: {
    envName: name
    appName: 'funcrecvstd'
    entityNameForScaling: 'order-standard-func'
    location: location
    imageName: funcRecvStdImageName != '' ? funcRecvStdImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module daprDistResources './daprdistributor.bicep' = {
  name: 'daprdist-resources'
  params: {
    envName: name
    appName: 'daprdistributor'
    entityNameForScaling: 'order-ingress-dapr'
    location: location
    imageName: daprDistImageName != '' ? daprDistImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module daprRecvExpResources './daprrecvexp.bicep' = {
  name: 'daprrecvexp-resources'
  params: {
    envName: name
    appName: 'daprrecvexp'
    entityNameForScaling: 'order-express-dapr'
    location: location
    imageName: daprRecvExpImageName != '' ? daprRecvExpImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module daprRecvStdResources './daprrecvstd.bicep' = {
  name: 'daprrecvstd-resources'
  params: {
    envName: name
    appName: 'daprrecvstd'
    entityNameForScaling: 'order-standard-dapr'
    location: location
    imageName: daprRecvStdImageName != '' ? daprRecvStdImageName : 'nginx:latest'
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
output APPINSIGHTS_CONNECTION_STRING string = appInsightsResources.outputs.APPINSIGHTS_CONNECTION_STRING
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_NAME
