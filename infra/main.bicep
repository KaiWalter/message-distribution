targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
}

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = {
  'azd-env-name': name
}

param testdataImageName string = ''

module resources './resources.bicep' = {
  name: 'resources-${resourceToken}'
  scope: resourceGroup
  params: {
    name: name
    location: location
    principalId: principalId
    resourceToken: resourceToken
    testdataImageName: testdataImageName
    tags: tags
  }
}

output SERVICEBUS_CONNECTION string = resources.outputs.SERVICEBUS_CONNECTION
output STORAGE_BLOB_CONNECTION string = resources.outputs.STORAGE_BLOB_CONNECTION
output APPINSIGHTS_CONNECTION_STRING string = resources.outputs.APPINSIGHTS_CONNECTION_STRING
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINER_REGISTRY_ACRPULL_ID string = resources.outputs.AZURE_CONTAINER_REGISTRY_ACRPULL_ID
output AZURE_KEY_VAULT_SERVICE_GET_ID string = resources.outputs.AZURE_KEY_VAULT_SERVICE_GET_ID
