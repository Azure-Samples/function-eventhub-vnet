param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param applicationInsightsName string = ''
param appServicePlanId string
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)
param storageAccountName string

// Runtime Properties
@allowed([
  'dotnet'
  'dotnetcore'
  'dotnet-isolated'
  'node'
  'python'
  'java'
  'powershell'
  'custom'
])
param runtimeName string

// Valid values for FUNCTIONS_WORKER_RUNTIME (https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings#functions_worker_runtime)
@allowed([
  'dotnet'
  'dotnet-isolated'
  'node'
  'python'
  'java'
  'powershell'
  'custom'
])
param functionsWorkerRuntime string
param runtimeNameAndVersion string = '${functionsWorkerRuntime}|${runtimeVersion}'
param runtimeVersion string

// Function Settings
@allowed([
  '~4'
  '~3'
  '~2'
  '~1'
])
param extensionVersion string = '~4'

// Microsoft.Web/sites Properties
@allowed(['functionapp', 'functionapp,linux'])
param kind string = 'functionapp,linux'

// Microsoft.Web/sites/config
param allowedOrigins array = []
param alwaysOn bool = true
param appCommandLine string = ''
@secure()
param appSettings object = {}
param clientAffinityEnabled bool = false
param enableOryxBuild bool = contains(kind, 'linux')
param functionAppScaleLimit int = -1
param linuxFxVersion string = runtimeNameAndVersion
param minimumElasticInstanceCount int = -1
param numberOfWorkers int = -1
param scmDoBuildDuringDeployment bool = true
param use32BitWorkerProcess bool = false

// NEW
param vnetRouteAllEnabled bool = false
param functionsRuntimeScaleMonitoringEnabled bool = false
param userAssignedIdentityName string = ''
param virtualNetworkIntegrationSubnetId string = ''
param storageKeyVaultSecretName string = 'storage-connection-string'

//NEW
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing =
  if (!empty(userAssignedIdentityName)) {
    name: userAssignedIdentityName
  }

module functions 'appservice.bicep' = {
  name: '${name}-functions'
  params: {
    name: name
    location: location
    tags: tags
    allowedOrigins: allowedOrigins
    alwaysOn: alwaysOn
    appCommandLine: appCommandLine
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    appSettings: union(
      appSettings,
      {
        FUNCTIONS_EXTENSION_VERSION: extensionVersion
        FUNCTIONS_WORKER_RUNTIME: functionsWorkerRuntime
      },
      // Use the managed idenitty if available, otherwise use connection string in Key Vault.
      (managedIdentity)
        ? { AzureWebJobsStorage__accountName: storage.name }
        : {
            AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${storageKeyVaultSecretName})'
          }
    )
    // If not using managed identity or Key Vault, use the connections string.
    // { AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}' }

    clientAffinityEnabled: clientAffinityEnabled
    enableOryxBuild: enableOryxBuild
    functionAppScaleLimit: functionAppScaleLimit
    keyVaultName: keyVaultName
    kind: kind
    linuxFxVersion: linuxFxVersion
    managedIdentity: managedIdentity
    minimumElasticInstanceCount: minimumElasticInstanceCount
    numberOfWorkers: numberOfWorkers
    runtimeName: runtimeName
    runtimeVersion: runtimeVersion
    runtimeNameAndVersion: runtimeNameAndVersion
    scmDoBuildDuringDeployment: scmDoBuildDuringDeployment
    use32BitWorkerProcess: use32BitWorkerProcess

    //NEW
    virtualNetworkSubnetId: empty(virtualNetworkIntegrationSubnetId) ? '' : virtualNetworkIntegrationSubnetId
    keyVaultReferenceIdentity: empty(userAssignedIdentityName) ? '' : uami.id
    vnetRouteAllEnabled: vnetRouteAllEnabled
    functionsRuntimeScaleMonitoringEnabled: functionsRuntimeScaleMonitoringEnabled
    functionsExtensionVersion: extensionVersion
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

output identityPrincipalId string = managedIdentity ? functions.outputs.identityPrincipalId : ''
output name string = functions.outputs.name
output uri string = functions.outputs.uri
output id string = functions.outputs.id
