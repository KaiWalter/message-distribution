@minLength(1)
@maxLength(64)
@description('Name of the environment (which is used to generate a short unqiue hash used in all resources).')
param envName string

@minLength(1)
@maxLength(64)
@description('Name of the container app.')
param appName string
var appShort = substring(replace(appName, '-', ''), 0, 8)

param queueNameForScaling string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string

var resourceToken = toLower(uniqueString(subscription().id, envName, location))
var tags = {
  'azd-env-name': envName
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

resource capp 'Microsoft.App/containerApps@2022-03-01' = {
  name: '${appName}-${resourceToken}'
  location: location
  tags: union(tags, {
      'azd-service-name': appShort
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
      dapr: {
        enabled: true
        appId: appName
        appPort: 80
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: imageName
          name: appName
          env: []
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                port: 80
                path: 'health'
              }
            }
            {
              type: 'Readiness'
              httpGet: {
                port: 80
                path: 'health'
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
                queueName: queueNameForScaling
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
        objectId: capp.identity.principalId
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
