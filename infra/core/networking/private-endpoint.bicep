param privateEndpointName string
param location string
param subnetId string
param privateLinkServiceConnectionName string = 'privateLinkServiceConnection'
param privateLinkServiceId string
param groupIds array = []
param virtualNetworkName string
param dnsZoneName string

module privateDnsZone 'private-dns-zone.bicep' = {
  name: '${deployment().name}-private-dns-zone'
  params: {
    dnsZoneLinkName: '${virtualNetworkName}-dns-link'
    dnsZoneName: dnsZoneName
    virtualNetworkName: virtualNetworkName
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkServiceConnectionName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }

  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: '${deployment().name}-private-dns-zone-group'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: privateDnsZone.outputs.privateDnsZoneId
          }
        }
      ]
    }
  }
}
