param location string
param principalId string = ''
param resourceToken string
param tags object

resource miKeyVaultGet 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'keyvault${resourceToken}-kv-get'
  location: location
}

var policies = union([
    {
      objectId: miKeyVaultGet.properties.principalId
      permissions: {
        secrets: [
          'get'
          'list'
        ]
      }
      tenantId: subscription().tenantId
    }
  ], (empty(principalId)) ? [] : [
    {
      objectId: principalId
      permissions: {
        secrets: [
          'get'
          'list'
        ]
      }
      tenantId: subscription().tenantId
    }
  ]
)

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: 'keyvault${resourceToken}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enablePurgeProtection: null
    accessPolicies: policies
  }

}

output AZURE_KEY_VAULT_ENDPOINT string = keyVault.properties.vaultUri
output AZURE_KEY_VAULT_SERVICE_GET_ID string = miKeyVaultGet.id
