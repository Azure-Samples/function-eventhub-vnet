param name string
param location string = resourceGroup().location
param tags object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output userPrincipalId string = userAssignedIdentity.properties.principalId
output name string = userAssignedIdentity.name
