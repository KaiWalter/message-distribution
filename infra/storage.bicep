param resourceToken string
param location string
param skuName string = 'Standard_LRS'
param kindName string = 'StorageV2'
param tags object

resource stg 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'st${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kindName
  properties: {
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

output STORAGE_BLOB_ENDPOINT string = stg.properties.primaryEndpoints.blob
