@minLength(1)
@maxLength(64)
@description('Name of the environment (which is used to generate a short unqiue hash used in all resources).')
param envName string

@minLength(1)
@maxLength(64)
@description('Name of the container app.')
param appName string
param instance string = ''

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
  name: 'stg${resourceToken}'
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: 'sb-${resourceToken}'
}

var effectiveImageName = imageName != '' ? imageName : 'azurefunctionstest.azurecr.io/azure-functions/dotnet7-quickstart-demo:1.0'

var queueName = {
  ingress: {
    name: 'q-order-ingress-func'
  }
  express: {
    name: 'q-order-express-func'
  }
  standard: {
    name: 'q-order-standard-func'
  }
}

resource capp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${envName}${appName}'
  location: location
  tags: union(tags, {
      'azd-service-name': appName
    })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acrPullId}': {}
      '${kvGetId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
        {
          name: 'storage-connection'
          value: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};AccountKey=${stg.listkeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'servicebus-connection'
          value: '${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString}'
        }
      ]
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: acrPullId
        }
      ]
    }
    template: {
      containers: [
        {
          image: effectiveImageName
          name: appName
          env: [
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'AZURE_KEY_VAULT_ENDPOINT'
              value: keyVault.properties.vaultUri
            }
            {
              name: 'AzureWebJobsStorage'
              secretRef: 'storage-connection'
            }
            {
              name: 'STORAGE_CONNECTION'
              secretRef: 'storage-connection'
            }
            {
              name: 'SERVICEBUS_CONNECTION'
              secretRef: 'servicebus-connection'
            }
            {
              name: 'QUEUE_NAME_INGRESS'
              value: queueName.ingress.name
            }
            {
              name: 'QUEUE_NAME_EXPRESS'
              value: queueName.express.name
            }
            {
              name: 'QUEUE_NAME_STANDARD'
              value: queueName.standard.name
            }
            {
              name: 'QUEUE_NAME'
              value: queueName[instance].name
            }
            {
              name: 'INSTANCE'
              value: instance
            }
            {
              name: 'WEBSITE_SITE_NAME'
              value: appName
            }
            {
              name: 'AzureFunctionsWebHost__hostId'
              value: guid(subscription().subscriptionId, resourceGroup().name)
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                port: 80
                path: 'api/health'
              }
            }
            {
              type: 'Readiness'
              httpGet: {
                port: 80
                path: 'api/health'
              }
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'queue-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: queueName[instance].name
                messageCount: '100'
              }
              auth: [
                {
                  secretRef: 'servicebus-connection'
                  triggerParameter: 'connection'
                }
              ]
            }

          }
        ]
      }
    }
  }
}