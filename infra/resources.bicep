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

module funcDistResources './funcdist.bicep' = {
  name: 'funcdist-resources'
  params: {
    name: name
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
    name: name
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
    name: name
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

module daprDistResources './daprdist.bicep' = {
  name: 'daprdist-resources'
  params: {
    envName: name
    appName: 'dapr-distributor'
    queueNameForScaling: 'order-ingress-dapr'
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
    appName: 'dapr-recvexp'
    queueNameForScaling: 'order-express-dapr'
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
    appName: 'dapr-recvstd'
    queueNameForScaling: 'order-standard-dapr'
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
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_NAME
