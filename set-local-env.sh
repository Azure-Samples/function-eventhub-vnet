#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Load environment variables used in Azure Functions from the AZD environment file.

echo "Loading azd .env file from current environment"

# Use the `get-values` azd command to retrieve environment variables from the `.env` file
# Example from https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/azd-extensibility#use-environment-variables-with-hooks.
while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values) 
EOF

# ----- Alternative approach -----
# AZD_ENVIRONMENT_NAME=$(jq -r '.defaultEnvironment' .azure/config.json)
# echo "Loading environment variables from .env file for AZD environment '$AZD_ENVIRONMENT_NAME'."

# set -a
# source "./.azure/$AZD_ENVIRONMENT_NAME/.env"
# set +a

