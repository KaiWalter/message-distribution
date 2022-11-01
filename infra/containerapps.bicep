param location string
param resourceToken string
param tags object

resource sb 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: 'sb-${resourceToken}'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: 'log-${resourceToken}'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'appi-${resourceToken}'
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
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
    // daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
  }

  resource comOrderIngress 'daprComponents' = {
    name: 'order-ingress-dapr'
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
          value: 'order-ingress-dapr'
        }
        // { wait for Dapr 1.10
        //   name: 'maxBulkSubCount'
        //   value: '100'
        // }
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
      ]
    }
  }

  resource comOrderPubSub 'daprComponents' = {
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
        // { wait for Dapr 1.10
        //   name: 'maxBulkSubCount'
        //   value: '100'
        // }
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

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name
