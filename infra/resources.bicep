param name string
param location string
param principalId string = ''
param resourceToken string
param tags object

param daprDistributorImageName string = ''
param daprRecvExpImageName string = ''
param daprRecvStdImageName string = ''
param funcDistributorImageName string = ''
param funcRecvExpImageName string = ''
param funcRecvStdImageName string = ''
param testdataImageName string = ''
param daprApiToken string = ''
param daprGrpcEndpoint string = ''
param daprHttpEndpoint string = ''
param daprPort string = ''

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
    skuName: 'Premium'
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

module acafDistResources './acafdistributor.bicep' = {
  name: 'acafdist-resources'
  params: {
    envName: name
    appName: 'acafdistributor'
    location: location
    imageName: funcDistributorImageName
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module acafRecvExpResources './acafrecvexp.bicep' = {
  name: 'acafrecvexp-resources'
  params: {
    envName: name
    appName: 'acafrecvexp'
    location: location
    imageName: funcRecvExpImageName
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module acafRecvStdResources './acafrecvstd.bicep' = {
  name: 'acafrecvstd-resources'
  params: {
    envName: name
    appName: 'acafrecvstd'
    location: location
    imageName: funcRecvStdImageName
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
    entityNameForScaling: 'q-order-ingress-func'
    location: location
    imageName: funcDistributorImageName != '' ? funcDistributorImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
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
    entityNameForScaling: 'q-order-express-func'
    location: location
    imageName: funcRecvExpImageName != '' ? funcRecvExpImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
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
    entityNameForScaling: 'q-order-standard-func'
    location: location
    imageName: funcRecvStdImageName != '' ? funcRecvStdImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
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
    entityNameForScaling: 'q-order-ingress-dapr'
    location: location
    imageName: daprDistributorImageName != '' ? daprDistributorImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
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
    entityNameForScaling: 'q-order-express-dapr'
    location: location
    imageName: daprRecvExpImageName != '' ? daprRecvExpImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
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
    entityNameForScaling: 'q-order-standard-dapr'
    location: location
    imageName: daprRecvStdImageName != '' ? daprRecvStdImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module dcraDistResources './dcradistributor.bicep' = {
  name: 'dcradist-resources'
  params: {
    envName: name
    appName: 'dcradistributor'
    entityNameForScaling: 'q-order-ingress-dcra'
    location: location
    imageName: daprDistributorImageName != '' ? daprDistributorImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
    daprApiToken: daprApiToken
    daprGrpcEndpoint: daprGrpcEndpoint
    daprHttpEndpoint: daprHttpEndpoint
    daprPort: daprPort
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module dcraRecvExpResources './dcrarecvexp.bicep' = {
  name: 'dcrarecvexp-resources'
  params: {
    envName: name
    appName: 'dcrarecvexp'
    entityNameForScaling: 'q-order-express-dcra'
    location: location
    imageName: daprRecvExpImageName != '' ? daprRecvExpImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
    daprApiToken: ''
    daprGrpcEndpoint: ''
    daprHttpEndpoint: ''
    daprPort: ''
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module dcraRecvStdResources './dcrarecvstd.bicep' = {
  name: 'dcrarecvstd-resources'
  params: {
    envName: name
    appName: 'dcrarecvstd'
    entityNameForScaling: 'q-order-standard-dcra'
    location: location
    imageName: daprRecvStdImageName != '' ? daprRecvStdImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
    daprApiToken: ''
    daprGrpcEndpoint: ''
    daprHttpEndpoint: ''
    daprPort: ''
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

module testdataResources './testdata.bicep' = {
  name: 'testdata-resources'
  params: {
    envName: name
    appName: 'testdata'
    location: location
    imageName: testdataImageName != '' ? testdataImageName : 'nginx:latest'
    acrPullId: containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
    kvGetId: keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
    daprApiToken: daprApiToken
    daprHttpEndpoint: daprHttpEndpoint
  }
  dependsOn: [
    containerAppsResources
    appInsightsResources
    keyVaultResources
    serviceBusResources
  ]
}

output ENVIRONMENT_NAME string = containerAppsResources.outputs.ENVIRONMENT_NAME
output STORAGE_NAME string = storageResources.outputs.STORAGE_NAME
output APPINSIGHTS_NAME string = appInsightsResources.outputs.APPINSIGHTS_NAME
output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output APPINSIGHTS_CONNECTION_STRING string = appInsightsResources.outputs.APPINSIGHTS_CONNECTION_STRING
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINER_REGISTRY_ACRPULL_ID string = containerAppsResources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
output AZURE_KEY_VAULT_SERVICE_GET_ID string = keyVaultResources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
output TESTDATA_URI string = testdataResources.outputs.TESTDATA_URI
