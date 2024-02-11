param resourceToken string
param location string
param skuName string = 'Standard'
param tags object

var queues = [
  // (regular) Functions Container on ACA
  'q-order-ingress-func'
  'q-order-standard-func'
  'q-order-express-func'
  // Functions on ACA
  'q-order-ingress-acaf'
  'q-order-standard-acaf'
  'q-order-express-acaf'
  // ASP.NET Core with Dapr Container on ACA
  'q-order-ingress-dapr'
  'q-order-standard-dapr'
  'q-order-express-dapr'
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

}