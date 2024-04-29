metadata description = 'Creates an Azure App Service in an existing Azure App Service plan.'
param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param applicationInsightsName string = ''
param appServicePlanId string
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)

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
param runtimeNameAndVersion string = '${runtimeName}|${runtimeVersion}'
param runtimeVersion string

// Microsoft.Web/sites Properties
param kind string = 'app,linux'

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
param scmDoBuildDuringDeployment bool = false
param use32BitWorkerProcess bool = false
param ftpsState string = 'FtpsOnly'
param healthCheckPath string = ''

//NEW
param virtualNetworkSubnetId string = ''
param keyVaultReferenceIdentity string = ''
param vnetRouteAllEnabled bool = false
param functionsRuntimeScaleMonitoringEnabled bool = false
param functionsExtensionVersion string = ''

var isFunctionApp = contains(kind, 'functionapp')

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    serverFarmId: appServicePlanId

    // NEW
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : null

    // NEW - Use for user-assigned managed identity.
    keyVaultReferenceIdentity: !empty(keyVaultReferenceIdentity) ? keyVaultReferenceIdentity : null

    siteConfig: {
      // NEW
      vnetRouteAllEnabled: vnetRouteAllEnabled
      functionsRuntimeScaleMonitoringEnabled: functionsRuntimeScaleMonitoringEnabled
      appSettings: isFunctionApp
        ? [
            {
              name: 'FUNCTIONS_EXTENSION_VERSION'
              value: functionsExtensionVersion
            }
          ]
        : []

      linuxFxVersion: linuxFxVersion

      alwaysOn: alwaysOn
      ftpsState: ftpsState
      minTlsVersion: '1.2'
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers != -1 ? numberOfWorkers : null
      minimumElasticInstanceCount: minimumElasticInstanceCount != -1 ? minimumElasticInstanceCount : null
      use32BitWorkerProcess: use32BitWorkerProcess
      functionAppScaleLimit: functionAppScaleLimit != -1 ? functionAppScaleLimit : null
      healthCheckPath: healthCheckPath
      cors: {
        allowedOrigins: union(['https://portal.azure.com', 'https://ms.portal.azure.com'], allowedOrigins)
      }
    }
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: true
  }

  // TODO: Support user assigned managed identity.
  identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }

  // NOTE: App Service logs aren't used for Function Apps.This isn't working with EP plans
  // when setting WEBSITE_CONTENTAZUREFILECONNECTIONSTRING and WEBSITE_CONTENTSHARE
  resource configLogs 'config' =
    if (!isFunctionApp) {
      name: 'logs'
      properties: {
        applicationLogs: { fileSystem: { level: 'Verbose' } }
        detailedErrorMessages: { enabled: true }
        failedRequestsTracing: { enabled: true }
        httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
      }
    }

  resource basicPublishingCredentialsPoliciesFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    location: location
    properties: {
      allow: false
    }
  }

  resource basicPublishingCredentialsPoliciesScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    location: location
    properties: {
      allow: false
    }
  }
}

// Updates to the single Microsoft.sites/web/config resources that need to be performed sequentially
// sites/web/config 'appsettings'
module configAppSettings 'appservice-appsettings.bicep' = {
  name: '${name}-appSettings'
  params: {
    name: appService.name
    appSettings: union(
      appSettings,
      {
        SCM_DO_BUILD_DURING_DEPLOYMENT: string(scmDoBuildDuringDeployment)
        ENABLE_ORYX_BUILD: string(enableOryxBuild)
      },
      runtimeName == 'python' && appCommandLine == '' ? { PYTHON_ENABLE_GUNICORN_MULTIWORKERS: 'true' } : {},
      !empty(applicationInsightsName)
        ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString }
        : {},
      !empty(keyVaultName) ? { AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri } : {}
    )
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing =
  if (!(empty(keyVaultName))) {
    name: keyVaultName
  }

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing =
  if (!empty(applicationInsightsName)) {
    name: applicationInsightsName
  }

output identityPrincipalId string = managedIdentity ? appService.identity.principalId : ''
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'

//NEW
output id string = appService.id
