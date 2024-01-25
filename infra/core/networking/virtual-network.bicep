param name string
param location string = resourceGroup().location
param tags object = {}

param virtualNetworkAddressSpacePrefix string
param subnets array = []

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpacePrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
        networkSecurityGroup: contains(subnet, 'networkSecurityGroupId') ? {
          id: subnet.networkSecurityGroupId
        } : null
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : null

      }
    }]
  }
}

output virtualNetworkName string = vnet.name
output virtualNetworkId string = vnet.id
output virtualNetworkSubnets array = vnet.properties.subnets
