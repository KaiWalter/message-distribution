param resourceToken string
param location string
param skuName string = 'Standard'
param tags object

var queues = [
  'q-order-ingress-func'
  'q-order-standard-func'
  'q-order-express-func'
  'q-order-ingress-dapr'
  'q-order-standard-dapr'
  'q-order-express-dapr'
]

var topics = [
  't-order-ingress-func'
  't-order-express-func'
  't-order-standard-func'
  't-order-ingress-dapr'
  't-order-express-dapr'
  't-order-standard-dapr'
]

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: 'sb-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
  }

  resource queueResources 'queues' = [for q in queues: {
    name: q
    properties: {
      maxSizeInMegabytes: 4096
    }
  }]

  resource topicResources 'topics' = [for t in topics: {
    name: t
    properties: {
      maxSizeInMegabytes: 4096
    }
  }]

}

output SERVICEBUS_CONNECTION string = '${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString}'
