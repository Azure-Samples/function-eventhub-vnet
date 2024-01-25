param name string
param location string = resourceGroup().location
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    // TODO: Handle security rules
  }
}

output id string = networkSecurityGroup.id
