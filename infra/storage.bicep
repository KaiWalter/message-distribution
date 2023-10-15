param resourceToken string
param location string
param skuName string = 'Standard_LRS'
param kindName string = 'StorageV2'
param tags object

resource stg 'Microsoft.Storage/storageAccounts@2022-05-01' = {
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
      defaultAction: 'Allow'
      bypass: 'None'
    }
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  name: 'default'
  parent: stg
}

resource contTestData 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: 'test-data'
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}

output STORAGE_NAME string = stg.name
