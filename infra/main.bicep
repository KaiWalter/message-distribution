targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${environmentName}-rg'
  location: location
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
}

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
param daprPubSubModel string = 'bulk'

param daprDistributorImageName string = ''
param daprReceiverImageName string = ''
param funcDistributorImageName string = ''
param funcReceiverImageName string = ''
param testdataImageName string = ''

module resources './resources.bicep' = {
  name: 'resources-${resourceToken}'
  scope: resourceGroup
  params: {
    name: environmentName
    location: location
    principalId: principalId
    resourceToken: resourceToken
    daprDistributorImageName: daprDistributorImageName
    daprReceiverImageName: daprReceiverImageName
    funcDistributorImageName: funcDistributorImageName
    funcReceiverImageName: funcReceiverImageName
    testdataImageName: testdataImageName
    daprComponentsModel: daprComponentsModel
    daprPubSubModel: daprPubSubModel
    tags: tags
  }
}

output ENVIRONMENT_NAME string = resources.outputs.ENVIRONMENT_NAME
output RESOURCE_GROUP_NAME string = resourceGroup.name
output STORAGE_NAME string = resources.outputs.STORAGE_NAME
output APPINSIGHTS_NAME string = resources.outputs.APPINSIGHTS_NAME
output APPINSIGHTS_INSTRUMENTATIONKEY string = resources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output APPINSIGHTS_CONNECTION_STRING string = resources.outputs.APPINSIGHTS_CONNECTION_STRING
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINER_REGISTRY_ACRPULL_ID string = resources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
output AZURE_KEY_VAULT_SERVICE_GET_ID string = resources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
output TESTDATA_URI string = resources.outputs.TESTDATA_URI
