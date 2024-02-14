param location string
param resourceToken string
param tags object

@description('determines whether bindings or pubsub is deployed for the experiment')
@allowed([
  'bindings'
  'pubsub'
])
param daprComponentsModel string

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

// switch valid application ids for the respective deployment model
var scopesBindings = daprComponentsModel == 'bindings' ? {
  distributor: 'daprdistributor'
  recvexp: 'daprrecvexp'
  recvstd: 'daprrecvstd'
} : {
  distributor: 'skip'
  recvexp: 'skip'
  recvstd: 'skip'
}

var scopesPubSub = daprComponentsModel == 'pubsub' ? [
  'daprdistributor'
  'daprrecvexp'
  'daprrecvstd'
] : [
  'skip'
]

var queueComponents = [
  {
    name: 'q-order-ingress-dapr-input'
    queueName: 'q-order-ingress-dapr'
    scopes: [
      scopesBindings.distributor
    ]
  }
  {
    name: 'q-order-express-dapr-output'
    queueName: 'q-order-express-dapr'
    scopes: [
      scopesBindings.distributor
    ]
  }
  {
    name: 'q-order-standard-dapr-output'
    queueName: 'q-order-standard-dapr'
    scopes: [
      scopesBindings.distributor
    ]
  }
  {
    name: 'q-order-express-dapr-input'
    queueName: 'q-order-express-dapr'
    scopes: [
      scopesBindings.recvexp
    ]
  }
  {
    name: 'q-order-standard-dapr-input'
    queueName: 'q-order-standard-dapr'
    scopes: [
      scopesBindings.recvstd
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
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
      // {
      //   name: 'Dedicated'
      //   workloadProfileType: 'E8'
      //   minimumCount: 3
      //   maximumCount: 5
      // }
    ]
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
          name: 'maxActiveMessages'
          value: '1000'
        }
        {
          name: 'maxConcurrentHandlers'
          value: '10'
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
      componentType: 'pubsub.azure.servicebus.queues'
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
          name: 'maxActiveMessages'
          value: '250'
        }
        {
          name: 'maxConcurrentHandlers'
          value: '1'
        }
      ]
      scopes: scopesPubSub
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
