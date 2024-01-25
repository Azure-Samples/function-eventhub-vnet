param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([ 'Basic', 'Standard', 'Premium' ])
param sku string = 'Standard'
param capacity int = 1

param useVirtualNetworkPrivateEndpoint bool = false

resource namespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
    capacity: capacity
  }

  resource networkRules 'networkRuleSets' = {
    name: 'default'
    properties: {
      defaultAction: useVirtualNetworkPrivateEndpoint ? 'Deny' : 'Allow'
      publicNetworkAccess: useVirtualNetworkPrivateEndpoint ? 'Disabled' : 'Enabled'
    }
  }
}

output eventHubNamespaceName string = namespace.name
