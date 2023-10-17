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

param daprDistributorImageName string = ''
param daprRecvExpImageName string = ''
param daprRecvStdImageName string = ''
param funcDistributorImageName string = ''
param funcRecvExpImageName string = ''
param funcRecvStdImageName string = ''
param testdataImageName string = ''
param daprApiToken string = ''
param daprGrpcEndpoint string = ''
param daprPort string = ''

module resources './resources.bicep' = {
  name: 'resources-${resourceToken}'
  scope: resourceGroup
  params: {
    name: environmentName
    location: location
    principalId: principalId
    resourceToken: resourceToken
    daprDistributorImageName: daprDistributorImageName
    daprRecvExpImageName: daprRecvExpImageName
    daprRecvStdImageName: daprRecvStdImageName
    funcDistributorImageName: funcDistributorImageName
    funcRecvExpImageName: funcRecvExpImageName
    funcRecvStdImageName: funcRecvStdImageName
    testdataImageName: testdataImageName
    daprApiToken: daprApiToken
    daprGrpcEndpoint: daprGrpcEndpoint
    daprPort: daprPort
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
