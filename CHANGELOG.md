# Azure Samples: Azure Function with Event Hub and Virtual Network Changelog

## 2024-03-04

### Features

* Add script to set AZD environment variables for local Azure Functions runtime (debugging).

### Bug Fixes

* Refactor Azure Function class names. Resolves [#6](https://github.com/Azure-Samples/function-eventhub-vnet/issues/6).
* Azure resources used by Azure Function app are saved in Azure Developer CLI (AZD) environment (via Bicep output parameters). Resolves [#9](https://github.com/Azure-Samples/function-eventhub-vnet/issues/9).
* Modify getting started instructions to include doing so via `git clone` and `azd init`. Resolves [#7](https://github.com/Azure-Samples/function-eventhub-vnet/issues/7).

### Breaking Changes

* None
