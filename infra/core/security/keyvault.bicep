param name string
param location string = resourceGroup().location
param tags object = {}

param principalId string = ''

// NEW
param enabledForRbacAuthorization bool = false
param useVirtualNetworkPrivateEndpoint bool = false
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = useVirtualNetworkPrivateEndpoint ? 'Disabled' : 'Enabled'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: enabledForRbacAuthorization
    accessPolicies: !empty(principalId) ? [
      {
        objectId: principalId
        permissions: { secrets: [ 'get', 'list' ] }
        tenantId: subscription().tenantId
      }
    ] : []
    publicNetworkAccess: publicNetworkAccess
  }
}

output endpoint string = keyVault.properties.vaultUri
output name string = keyVault.name
