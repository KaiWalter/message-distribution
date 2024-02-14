param name string
param location string
param principalId string = ''
param resourceToken string
param tags object

param daprDistributorImageName string = ''
param daprReceiverImageName string = ''
param funcDistributorImageName string = ''
param funcReceiverImageName string = ''
param testdataImageName string = ''

@description('determines whether bindings or pubsub is deployed for the experiment')
@allowed([
  'bindings'
  'pubsub'
])
param daprComponentsModel string
@description('determines whether single or bulk pubsub is used')
@allowed([
  'bulk'
  'single'
])
param daprPubSubModel string

module containerAppsResources './containerapps.bicep' = {
  name: 'containerapps-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
    daprComponentsModel: daprComponentsModel
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

module acafRecvExpResources './acafrecvexp.bicep' = {
  name: 'acafrecvexp-resources'
  params: {
    envName: name
    appName: 'acafrecvexp'
    location: location
    imageName: funcReceiverImageName
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

module acafRecvStdResources './acafrecvstd.bicep' = {
  name: 'acafrecvstd-resources'
  params: {
    envName: name
    appName: 'acafrecvstd'
    location: location
    imageName: funcReceiverImageName
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

module funcDistResources './funcdistributor.bicep' = {
  name: 'funcdist-resources'
  params: {
    envName: name
    appName: 'funcdistributor'
    location: location
    imageName: funcDistributorImageName
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
    location: location
    imageName: funcReceiverImageName
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
    location: location
    imageName: funcReceiverImageName
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
    daprPubSubModel: daprPubSubModel
    location: location
    imageName: daprDistributorImageName
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
    daprPubSubModel: daprPubSubModel
    location: location
    imageName: daprReceiverImageName
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
    daprPubSubModel: daprPubSubModel
    location: location
    imageName: daprReceiverImageName
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

module testdataResources './testdata.bicep' = {
  name: 'testdata-resources'
  params: {
    envName: name
    appName: 'testdata'
    location: location
    imageName: testdataImageName != '' ? testdataImageName : 'nginx:latest'
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
