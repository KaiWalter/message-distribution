param resourceToken string
param location string
param skuName string = 'Standard'
param tags object

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: 'sb-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
  }

  resource queueOrderIngress 'queues' = {
    name: 'order-ingress'
    properties: {
    }
  }

  resource queueOrderStandard 'queues' = {
    name: 'order-standard'
    properties: {
    }
  }

  resource queueOrderExpress 'queues' = {
    name: 'order-express'
    properties: {
    }
  }
}

output SERVICEBUS_CONNECTION string = '${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString}'
