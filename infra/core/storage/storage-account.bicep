param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Cool'
  'Hot'
  'Premium' ])
param accessTier string = 'Hot'
param allowBlobPublicAccess bool = true
param allowCrossTenantReplication bool = true
param allowSharedKeyAccess bool = true
param containers array = []
//NEW
param fileShares array = []
param defaultToOAuthAuthentication bool = false
param deleteRetentionPolicy object = {}
@allowed([ 'AzureDnsZone', 'Standard' ])
param dnsEndpointType string = 'Standard'
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'

param networkAcls object = {
  bypass: useVirtualNetworkPrivateEndpoint ? 'None' : 'AzureServices'
  defaultAction: useVirtualNetworkPrivateEndpoint ? 'Deny' : 'Allow'
}
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = useVirtualNetworkPrivateEndpoint ? 'Disabled' : 'Enabled'

param sku object = { name: 'Standard_LRS' }

//NEW
param useVirtualNetworkPrivateEndpoint bool = false
param keyVaultName string = ''
param keyVaultSecretName string = 'storage-connection-string'

module storageKeyVaultSecret '../security/keyvault-secret.bicep' = if (!empty(keyVaultName)) {
  name: 'storageKeyVaultSecret'
  params: {
    keyVaultName: keyVaultName
    name: keyVaultSecretName
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    dnsEndpointType: dnsEndpointType
    minimumTlsVersion: minimumTlsVersion
    networkAcls: networkAcls
    publicNetworkAccess: publicNetworkAccess
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    properties: {
      deleteRetentionPolicy: deleteRetentionPolicy
    }
    resource container 'containers' = [for container in containers: {
      name: container.name
      properties: {
        publicAccess: contains(container, 'publicAccess') ? container.publicAccess : 'None'
      }
    }]
  }

  resource fileServices 'fileServices' = if (!empty(fileShares)) {
    name: 'default'

    resource share 'shares' = [for item in fileShares: {
      name: item.name
    }]
  }
}

output name string = storage.name
output primaryEndpoints object = storage.properties.primaryEndpoints
output id string = storage.id
