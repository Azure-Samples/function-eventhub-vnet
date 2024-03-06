using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')
param useVirtualNetworkIntegration = bool(readEnvironmentVariable('USE_VIRTUAL_NETWORK_INTEGRATION', 'false'))
param useVirtualNetworkPrivateEndpoint = bool(readEnvironmentVariable('USE_VIRTUAL_NETWORK_PRIVATE_ENDPOINT', 'false'))
param virtualNetworkAddressSpacePrefix = readEnvironmentVariable('VIRTUAL_NETWORK_ADDRESS_SPACE_PREFIX', '10.1.0.0/16')
param virtualNetworkIntegrationSubnetAddressSpacePrefix = readEnvironmentVariable('VIRTUAL_NETWORK_INTEGRATION_SUBNET_ADDRESS_SPACE_PREFIX', '10.1.1.0/24')
param virtualNetworkPrivateEndpointSubnetAddressSpacePrefix = readEnvironmentVariable('VIRTUAL_NETWORK_PRIVATE_ENDPOINT_SUBNET_ADDRESS_SPACE_PREFIX', '10.1.2.0/24')
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param principalType = readEnvironmentVariable('AZURE_PRINCIPAL_TYPE', 'User')
