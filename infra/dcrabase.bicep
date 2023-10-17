@minLength(1)
@maxLength(64)
@description('Name of the environment (which is used to generate a short unqiue hash used in all resources).')
param envName string

@minLength(1)
@maxLength(64)
@description('Name of the container app.')
param appName string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string
param acrPullId string
param kvGetId string

param daprApiToken string
param daprGrpcEndpoint string
param daprPort string

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

resource stg 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: 'stg${resourceToken}'
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: 'sb-${resourceToken}'
}

resource capp 'Microsoft.App/containerApps@2022-10-01' = {
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
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      secrets: [
        {
          name: 'storage-connection'
          value: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};AccountKey=${stg.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'servicebus-connection'
          value: '${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString}'
        }
        {
          name: 'appinsights-connection'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'dapr-api-token'
          value: daprApiToken != '' ? daprApiToken : 'not-used'
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
          image: imageName
          name: appName
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              secretRef: 'appinsights-connection'
            }
            {
              name: 'TESTCASE'
              value: 'dcra'
            }
            {
              name: 'DAPR_API_TOKEN'
              secretRef: 'dapr-api-token'
            }
            {
              name: 'DAPR_GRPC_ENDPOINT'
              value: daprGrpcEndpoint
            }
            {
              name: 'DAPR_PORT'
              value: daprPort
            }
          ]
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
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}
