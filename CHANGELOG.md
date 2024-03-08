# Azure Samples: Azure Function with Event Hub and Virtual Network Changelog

## 2024-03-08

### Features

* Use Azure [Bicep's parameter file (a .bicepparam file)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameter-files?tabs=Bicep). AZD will default to using .bicepparam if present.
* Add new `AZURE_PRINCIPAL_TYPE` AZD environment variable and related Bicep input parameter, with a default value of "User".
* Dev container default to use latest version of Azure CLI.

### Bug Fixes

* Set new `AZURE_PRINCIPAL_TYPE` to "ServicePrincipal" when running GitHub workflow. Resolves [#11](https://github.com/Azure-Samples/function-eventhub-vnet/issues/11)

### Breaking Changes

* None

## 2024-03-04

### Features

* Add script to set AZD environment variables for local Azure Functions runtime (debugging).

### Bug Fixes

* Refactor Azure Function class names. Resolves [#6](https://github.com/Azure-Samples/function-eventhub-vnet/issues/6).
* Azure resources used by Azure Function app are saved in Azure Developer CLI (AZD) environment (via Bicep output parameters). Resolves [#9](https://github.com/Azure-Samples/function-eventhub-vnet/issues/9).
* Modify getting started instructions to include doing so via `git clone` and `azd init`. Resolves [#7](https://github.com/Azure-Samples/function-eventhub-vnet/issues/7).

### Breaking Changes

* None
