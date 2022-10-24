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

  resource queueOrderIngressFunc 'queues' = {
    name: 'order-ingress-func'
    properties: {
      maxSizeInMegabytes: 4096
    }
  }

  resource queueOrderStandardFunc 'queues' = {
    name: 'order-standard-func'
    properties: {
      maxSizeInMegabytes: 4096
    }
  }

  resource queueOrderExpressFunc 'queues' = {
    name: 'order-express-func'
    properties: {
      maxSizeInMegabytes: 4096
    }
  }

  resource queueOrderIngressDapr 'queues' = {
    name: 'order-ingress-dapr'
    properties: {
      maxSizeInMegabytes: 4096
    }
  }

  resource queueOrderStandardDapr 'queues' = {
    name: 'order-standard-dapr'
    properties: {
      maxSizeInMegabytes: 4096
    }
  }

  resource queueOrderExpressDapr 'queues' = {
    name: 'order-express-dapr'
    properties: {
      maxSizeInMegabytes: 4096
    }
  }
}

output SERVICEBUS_CONNECTION string = '${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString}'
