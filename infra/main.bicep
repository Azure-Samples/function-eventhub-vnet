targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param useVirtualNetworkIntegration bool = false
param useVirtualNetworkPrivateEndpoint bool = false
param virtualNetworkAddressSpacePrefix string = '10.1.0.0/16'
param virtualNetworkIntegrationSubnetAddressSpacePrefix string = '10.1.1.0/24'
param virtualNetworkPrivateEndpointSubnetAddressSpacePrefix string = '10.1.2.0/24'

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

var useVirtualNetwork = useVirtualNetworkIntegration || useVirtualNetworkPrivateEndpoint
var virtualNetworkName = '${abbrs.networkVirtualNetworks}${resourceToken}'
var virtualNetworkIntegrationSubnetName = '${abbrs.networkVirtualNetworksSubnets}${resourceToken}-int'
var virtualNetworkPrivateEndpointSubnetName = '${abbrs.networkVirtualNetworksSubnets}${resourceToken}-pe'

var eventHubConsumerGroupName = 'widgetfunctionconsumergroup'
var functionAppName = '${abbrs.webSitesFunctions}${resourceToken}'
var storageSecretName = 'storage-connection-string'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

@description('This is the built-in role definition for the Key Vault Secret User role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-secrets-user for more information.')
resource keyVaultSecretUserRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

@description('This is the built-in role definition for the Azure Event Hubs Data Receiver role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#azure-event-hubs-data-receiver for more information.')
resource eventHubDataReceiverUserRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
}

@description('This is the built-in role definition for the Azure Event Hubs Data Sender role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#azure-event-hubs-data-sender for more information.')
resource eventHubDataSenderUserRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '2b629674-e913-4c01-ae53-ef4638d8f975'
}

@description('This is the built-in role definition for the Azure Storage Blob Data Owner role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-owner for more information.')
resource storageBlobDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
}

// TODO: Scope to the specific resource (Event Hub, Storage, Key Vault) instead of the resource group.
//       See https://github.com/Azure/bicep/discussions/5926
module storageRoleAssignment 'core/security/role.bicep' = {
  name: 'storageRoleAssignment'
  scope: rg
  params: {
    principalId: functionApp.outputs.identityPrincipalId
    roleDefinitionId: storageBlobDataOwnerRoleDefinition.name
    principalType: 'ServicePrincipal'
  }
}

module eventHubReceiverRoleAssignment 'core/security/role.bicep' = {
  name: 'eventHubReceiverRoleAssignment'
  scope: rg
  params: {
    principalId: functionApp.outputs.identityPrincipalId
    roleDefinitionId: eventHubDataReceiverUserRoleDefintion.name
    principalType: 'ServicePrincipal'
  }
}

module eventHubSenderRoleAssignment 'core/security/role.bicep' = {
  name: 'eventHubSenderRoleAssignment'
  scope: rg
  params: {
    principalId: functionApp.outputs.identityPrincipalId
    roleDefinitionId: eventHubDataSenderUserRoleDefintion.name
    principalType: 'ServicePrincipal'
  }
}

module keyVaultRoleAssignment 'core/security/role.bicep' = {
  name: 'keyVaultRoleAssignment'
  scope: rg
  params: {
    principalId: functionApp.outputs.identityPrincipalId
    roleDefinitionId: keyVaultSecretUserRoleDefintion.name
    principalType: 'ServicePrincipal'
  }
}

module logAnalytics './core/monitor/loganalytics.bicep' = {
  name: 'logAnalytics'
  scope: rg
  params: {
    name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

module appInsights './core/monitor/applicationinsights.bicep' = {
  name: 'applicationInsights'
  scope: rg
  params: {
    name: '${abbrs.insightsComponents}${resourceToken}'
    tags: tags

    includeDashboard: false
    dashboardName: ''
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    location: location
  }
}

module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags

    fileShares: [
      {
        name: functionAppName
      }
    ]

    // Set the key vault name to set the connection string as a secret in the key vault.
    keyVaultName: keyVault.outputs.name
    keyVaultSecretName: storageSecretName

    useVirtualNetworkPrivateEndpoint: useVirtualNetworkPrivateEndpoint
  }
}

module eventHubNamespace './core/messaging/event-hub-namespace.bicep' = {
  name: 'eventHubNamespace'
  scope: rg
  params: {
    name: '${abbrs.eventHubNamespaces}${resourceToken}'
    location: location
    tags: tags

    sku: 'Standard'

    useVirtualNetworkPrivateEndpoint: useVirtualNetworkPrivateEndpoint
  }
}

module eventHub './core/messaging/event-hub.bicep' = {
  name: 'eventHub'
  scope: rg
  params: {
    name: '${abbrs.eventHubNamespacesEventHubs}widget'
    eventHubNamespaceName: eventHubNamespace.outputs.eventHubNamespaceName
    consumerGroupName: eventHubConsumerGroupName
  }
}

module keyVault 'core/security/keyvault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    enabledForRbacAuthorization: true
    useVirtualNetworkPrivateEndpoint: useVirtualNetworkPrivateEndpoint
  }
}

module integrationSubnetNsg 'core/networking/network-security-group.bicep' = if (useVirtualNetwork) {
  name: 'integrationSubnetNsg'
  scope: rg
  params: {
    name: '${abbrs.networkNetworkSecurityGroups}${resourceToken}-integration-subnet'
    location: location
  }
}

module privateEndpointSubnetNsg 'core/networking/network-security-group.bicep' = if (useVirtualNetwork) {
  name: 'privateEndpointSubnetNsg'
  scope: rg
  params: {
    name: '${abbrs.networkNetworkSecurityGroups}${resourceToken}-private-endpoint-subnet'
    location: location
  }
}

module vnet './core/networking/virtual-network.bicep' = if (useVirtualNetwork) {
  name: 'vnet'
  scope: rg
  params: {
    name: virtualNetworkName
    location: location
    tags: tags

    virtualNetworkAddressSpacePrefix: virtualNetworkAddressSpacePrefix

    // TODO: Find a better way to handle subnets. I'm not a fan of this array of object approach (losing Intellisense).
    subnets: [
      {
        name: virtualNetworkIntegrationSubnetName
        addressPrefix: virtualNetworkIntegrationSubnetAddressSpacePrefix
        networkSecurityGroupId: useVirtualNetwork ? integrationSubnetNsg.outputs.id : null

        delegations: [
          {
            name: 'delegation'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
      }
      {
        name: virtualNetworkPrivateEndpointSubnetName
        addressPrefix: virtualNetworkPrivateEndpointSubnetAddressSpacePrefix
        networkSecurityGroupId: useVirtualNetwork ? privateEndpointSubnetNsg.outputs.id : null
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
  }
}

// Sets up private endpoints and private dns zones for the resources.
module networking 'core/networking/private-networking.bicep' = if (useVirtualNetworkPrivateEndpoint) {
  name: 'networking'
  scope: rg
  params: {
    location: location
    eventHubNamespaceName: eventHubNamespace.outputs.eventHubNamespaceName
    keyVaultName: keyVault.outputs.name
    storageAccoutnName: storage.outputs.name
    functionName: functionApp.outputs.name
    virtualNetworkIntegrationSubnetName: virtualNetworkIntegrationSubnetName
    virtualNetworkName: virtualNetworkName
    virtualNetworkPrivateEndpointSubnetName: virtualNetworkPrivateEndpointSubnetName
  }
}

module functionPlan 'core/host/functionplan.bicep' = {
  name: 'functionPlan'
  scope: rg
  params: {
    location: location
    tags: tags
    OperatingSystem: 'Linux'
    name: '${abbrs.webServerFarms}${resourceToken}'
    planSku: 'EP1'
  }
}

module functionApp 'core/host/functions.bicep' = {
  name: 'functionApp'
  scope: rg
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': 'event-consumer-func' })
    name: functionAppName
    appServicePlanId: functionPlan.outputs.planId
    keyVaultName: keyVault.outputs.name
    storageKeyVaultSecretName: storageSecretName
    managedIdentity: true // creates a system assigned identity
    functionsWorkerRuntime: 'dotnet'
    runtimeName: 'dotnetcore'
    runtimeVersion: '6.0'
    extensionVersion: '~4'
    storageAccountName: storage.outputs.name
    vnetRouteAllEnabled: true
    kind: 'functionapp,linux'
    alwaysOn: false
    enableOryxBuild: false
    scmDoBuildDuringDeployment: false
    functionsRuntimeScaleMonitoringEnabled: true
    applicationInsightsName: appInsights.outputs.name
    virtualNetworkIntegrationSubnetId: useVirtualNetworkIntegration ? vnet.outputs.virtualNetworkSubnets[0].id : ''
    appSettings: {
      EVENTHUB_CONNECTION__fullyQualifiedNamespace: '${eventHubNamespace.outputs.eventHubNamespaceName}.servicebus.windows.net'
      EVENTHUB_NAME: eventHub.outputs.EventHubName
      EVENTHUB_CONSUMER_GROUP_NAME: eventHub.outputs.EventHubConsumerGroupName

      // Needed for EP plans
      WEBSITE_CONTENTSHARE: functionAppName
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.name};SecretName=${storageSecretName})'

      // If the storage account is private . . .
      WEBSITE_CONTENTOVERVNET: 1

      // WEBSITE_SKIP_CONTENTSHARE_VALIDATE should be set to 1 when using vnet private endpoint
      // for Azure Storage or when WEBSITE_CONTENTAZUREFILECONNECTIONSTRING uses a
      // key vault reference. See https://github.com/Azure/azure-functions-host/issues/7094
      WEBSITE_SKIP_CONTENTSHARE_VALIDATION: 1

      // Need the settings below if using (user-assigned) identity-based connection for AzureWebJobsStorage or EventHubConnection
      // EventHubConnection__clientId: uami.properties.clientId
      // EventHubConnection__credential: 'managedidentity'
      // AzureWebJobsStorage__accountName: storage.name
      // AzureWebJobsStorage__credential: 'managedidentity'
      // AzureWebJobsStorage__clientId: uami.properties.clientId

    }
  }
}

output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output EVENTHUB_CONSUMER_GROUP_NAME string = eventHub.outputs.EventHubConsumerGroupName
output EVENTHUB_NAME string = eventHub.outputs.EventHubName
output EVENTHUB_NAMESPACE string = eventHubNamespace.outputs.eventHubNamespaceName
output EVENTHUB_CONNECTION__fullyQualifiedNamespace string = '${eventHubNamespace.outputs.eventHubNamespaceName}.servicebus.windows.net'
