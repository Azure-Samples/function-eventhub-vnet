param virtualNetworkName string
param dnsZoneName string
param dnsZoneLinkName string

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: virtualNetworkName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'Global'

  resource privateDnsZoneGroup 'virtualNetworkLinks' = {
    name: dnsZoneLinkName
    location: 'Global'
    properties: {
      virtualNetwork: {
        id: vnet.id
      }
      registrationEnabled: false
    }
  }
}

output privateDnsZoneId string = privateDnsZone.id
