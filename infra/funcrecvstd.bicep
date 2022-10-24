@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = {
  'azd-env-name': name
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
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

resource funcrecvstd 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'func-recvstd-${resourceToken}'
  location: location
  tags: union(tags, {
      'azd-service-name': 'funcrecvstd'
    })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};AccountKey=${listKeys(stg.id, stg.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'servicebus-connection'
          value: '${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString}'
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: imageName
          name: 'func-recvstd'
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
              name: 'WEBSITE_SITE_NAME'
              value: 'func-recvstd'
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
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'queue-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: 'order-standard'
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

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2021-10-01' = {
  name: '${keyVault.name}/add'
  properties: {
    accessPolicies: [
      {
        objectId: funcrecvstd.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
