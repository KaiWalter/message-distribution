@minLength(1)
@maxLength(64)
@description('Name of the environment (which is used to generate a short unqiue hash used in all resources).')
param envName string

@minLength(1)
@maxLength(64)
@description('Name of the container app.')
param appName string

param entityNameForScaling string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string
param acrPullId string
param kvGetId string

var resourceToken = toLower(uniqueString(subscription().id, envName, location))
var tags = {
  'azd-env-name': envName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: 'cae-${resourceToken}'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: 'contreg${resourceToken}'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'appi-${resourceToken}'
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: 'keyvault${resourceToken}'
}

resource stg 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: 'st${resourceToken}'
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: 'sb-${resourceToken}'
}
var effectiveImageName = imageName != '' ? imageName : 'mcr.microsoft.com/azure-functions/dotnet7-quickstart-demo:1.0'

var appSetingsBasic = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};AccountKey=${stg.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
  {
    name: 'STORAGE_CONNECTION'
    value: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};AccountKey=${stg.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
  {
    name: 'SERVICEBUS_CONNECTION'
    value: '${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString}'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.properties.ConnectionString
  }
]

var appSetingsRegistry = [
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: containerRegistry.properties.loginServer
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
    value: containerRegistry.listCredentials().username
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
    value: containerRegistry.listCredentials().passwords[0].value
  }
  // https://github.com/Azure/Azure-Functions/wiki/When-and-Why-should-I-set-WEBSITE_ENABLE_APP_SERVICE_STORAGE
  // case 3a
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
]

var appSettings = concat(appSetingsBasic, imageName != '' ? appSetingsRegistry : [])

// var identity = imageName != '' ? {
//   type: 'UserAssigned'
//   userAssignedIdentities: {
//     '${acrPullId}': {}
//     '${kvGetId}': {}
//   }
// } : {
//   type: 'None'
// }
//
resource acafunction 'Microsoft.Web/sites@2022-09-01' = {
  name: '${envName}${appName}'
  location: location
  tags: union(tags, {
      'azd-service-name': appName
    })
  kind: 'functionapp'
  // identity: identity
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id

    siteConfig: {
      linuxFxVersion: 'DOCKER|${effectiveImageName}'
      appSettings: appSettings
    }
  }
}
