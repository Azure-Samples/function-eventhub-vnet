param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([ 'Windows', 'Linux' ])
param OperatingSystem string = 'Linux'

@allowed([ 'EP1', 'EP2', 'EP3', 'Consumption' ])
param planSku string

var functionSkuMap = {
  EP1: {
    name: 'EP1'
    tier: 'ElasticPremium'
    kind: 'elastic'
  }
  EP2: {
    name: 'EP2'
    tier: 'ElasticPremium'
    kind: 'elastic'
  }
  EP3: {
    name: 'EP3'
    tier: 'ElasticPremium'
    kind: 'elastic'
  }
  Consumption: {
    name: 'Y1'
    tier: 'Dynamic'
    kind: 'functionapp'
  }
}

module appServicePlan 'appserviceplan.bicep' = {
  name: '${name}-plan-module'
  params: {
    name: name
    location: location
    tags: tags

    // false == Windows; true == Linux
    reserved: OperatingSystem == 'Linux' ? true : false

    sku: {
      name: functionSkuMap[planSku].name
      tier: functionSkuMap[planSku].tier
    }
    kind: functionSkuMap[planSku].kind
  }
}

output planId string = appServicePlan.outputs.id
output planName string = appServicePlan.outputs.name
