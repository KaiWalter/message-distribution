param location string
param resourceToken string
param tags object

resource sb 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: 'sb-${resourceToken}'
}

resource stg 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: 'stg${resourceToken}'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: 'log-${resourceToken}'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'appi-${resourceToken}'
}

var queueComponents = [
  {
    name: 'q-order-ingress-dapr-input'
    queueName: 'q-order-ingress-dapr'
    scopes: [
      'daprdistributor'
    ]
  }
  {
    name: 'q-order-express-dapr-output'
    queueName: 'q-order-express-dapr'
    scopes: [
      'daprdistributor'
    ]
  }
  {
    name: 'q-order-standard-dapr-output'
    queueName: 'q-order-standard-dapr'
    scopes: [
      'daprdistributor'
    ]
  }
  {
    name: 'q-order-express-dapr-input'
    queueName: 'q-order-express-dapr'
    scopes: [
      'daprrecvexp'
    ]
  }
  {
    name: 'q-order-standard-dapr-input'
    queueName: 'q-order-standard-dapr'
    scopes: [
      'daprrecvstd'
    ]
  }
]

var blobComponents = [
  {
    name: 'express-output'
    containerName: 'express-outbox'
    scopes: [
      'daprrecvexp'
    ]
  }
  {
    name: 'standard-output'
    containerName: 'standard-outbox'
    scopes: [
      'daprrecvstd'
    ]
  }
]

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'cae-${resourceToken}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIConnectionString: appInsights.properties.ConnectionString
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
  }

  resource queueComponentResources 'daprComponents' = [for q in queueComponents: {
    name: q.name
    properties: {
      componentType: 'bindings.azure.servicebusqueues'
      version: 'v1'
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: '${listKeys('${sb.id}/AuthorizationRules/RootManageSharedAccessKey', sb.apiVersion).primaryConnectionString};EntityPath=orders'
        }
      ]
      metadata: [
        {
          name: 'connectionString'
          secretRef: 'sb-root-connectionstring'
        }
        {
          name: 'queueName'
          value: q.queueName
        }
        {
          name: 'maxBulkSubCount'
          value: '100'
        }
        {
          name: 'maxActiveMessages'
          value: '1000'
        }
        {
          name: 'maxConcurrentHandlers'
          value: '8'
        }
      ]
      scopes: q.scopes
    }
  }]

  resource blobComponentResources 'daprComponents' = [for b in blobComponents: {
    name: b.name
    properties: {
      componentType: 'bindings.azure.blobstorage'
      version: 'v1'
      secrets: [
        {
          name: 'storage-key'
          value: stg.listKeys().keys[0].value
        }
      ]
      metadata: [
        {
          name: 'accountKey'
          secretRef: 'storage-key'
        }
        {
          name: 'accountName'
          value: stg.name
        }
        {
          name: 'containerName'
          value: b.containerName
        }
      ]
      scopes: b.scopes
    }
  }]

  resource pubSubComponent 'daprComponents' = {
    name: 'order-pubsub'
    properties: {
      componentType: 'pubsub.azure.servicebus'
      version: 'v1'
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: '${listKeys('${sb.id}/AuthorizationRules/RootManageSharedAccessKey', sb.apiVersion).primaryConnectionString};EntityPath=orders'
        }
      ]
      metadata: [
        {
          name: 'connectionString'
          secretRef: 'sb-root-connectionstring'
        }
        {
          name: 'maxBulkSubCount'
          value: '100'
        }
        {
          name: 'maxActiveMessages'
          value: '1000'
        }
        {
          name: 'maxConcurrentHandlers'
          value: '8'
        }
      ]
      scopes: [
        'daprdistributor'
        'daprrecvexp'
        'daprrecvstd'
      ]
    }
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: 'contreg${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    encryption: {
      status: 'disabled'
    }
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

resource miAcrPull 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${containerRegistry.name}-acrpull'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: miAcrPull.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output ENVIRONMENT_NAME string = containerAppsEnvironment.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name
output AZURE_CONTAINER_REGISTRY_ACRPULL_ID string = miAcrPull.id
