param location string = resourceGroup().location
param virtualNetworkName string
param keyVaultName string
param eventHubNamespaceName string
param storageAccoutnName string
param functionName string
param virtualNetworkIntegrationSubnetName string
param virtualNetworkPrivateEndpointSubnetName string
var storageServices = [ 'table', 'blob', 'queue', 'file' ]

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: virtualNetworkName

  resource integrationSubnet 'subnets' existing = {
    name: virtualNetworkIntegrationSubnetName
  }

  resource privateEndpointSubnet 'subnets' existing = {
    name: virtualNetworkPrivateEndpointSubnetName
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubNamespaceName
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccoutnName
}

resource function 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionName
}

module keyVaultPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'keyVaultPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    privateEndpointName: 'pe-${keyVault.name}'
    location: location
    privateLinkServiceId: keyVault.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'vault' ]
  }
}

module storagePrivateEndpoint 'private-endpoint.bicep' = [for (svc, i) in storageServices: {
  name: '${svc}-storagePrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.${svc}.${environment().suffixes.storage}'
    location: location
    privateEndpointName: 'pe-${storage.name}-${svc}'
    privateLinkServiceId: storage.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [
      svc
    ]
  }
}]

module eventHubNamespacePrivateEndpoint 'private-endpoint.bicep' = {
  name: 'eventHubNamespacePrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.servicebus.windows.net'
    location: location
    privateEndpointName: 'pe-${eventHubNamespace.name}'
    privateLinkServiceId: eventHubNamespace.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'namespace' ]
  }
}

module functionPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'functionPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.azurewebsites.net'
    location: location
    privateEndpointName: 'pe-${function.name}'
    privateLinkServiceId: function.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'sites' ]
  }
}
