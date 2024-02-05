#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Load environment variables from AZD environment file.
# EVENTHUB_NAMESPACE
# AZURE_ENV_NAME
# AZURE_SUBSCRIPTION_ID
set -o allexport; source ./.azure/func-eventhub-localdev/.env; set +o allexport

# Try to get the current account details
az account show &> /dev/null

# Check the exit status of the last command
if [ $? -eq 0 ]; then
  echo "Logged in to Azure CLI."
else
  echo "Not logged in to Azure CLI. Attempting to log in..."
  az login
fi

echo "Setting the default subscription to $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Define the role IDs for the 'Azure Event Hubs Data Receiver' and 'Azure Event Hubs Data Owner' roles.
EVENT_HUBS_DATA_RECEIVER_ROLE_ID=$(az role definition list --name "Azure Event Hubs Data Receiver" --query []."name" -o tsv)
EVENT_HUBS_DATA_OWNER_ROLE_ID=$(az role definition list --name "Azure Event Hubs Data Owner" --query []."name" -o tsv)

# Define the resource group name (derived from the AZD environment name)
RESOURCE_GROUP_NAME="rg-$AZURE_ENV_NAME"

# Get the current user's ID.
ASSIGNEE_ID=$(az ad signed-in-user show --query userPrincipalName -o tsv)

# Define the ID for the resource scope.
EVENT_HUBS_NAMESPACE_ID="/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.EventHub/namespaces/$EVENTHUB_NAMESPACE"


# Assign self the 'Azure Event Hubs Data Receiver' role.
echo "Assigning the 'Azure Event Hubs Data Receiver' role to $ASSIGNEE_ID"
az role assignment create \
    --role "$EVENT_HUBS_DATA_RECEIVER_ROLE_ID" \
    --assignee "$ASSIGNEE_ID" \
    --scope "$EVENT_HUBS_NAMESPACE_ID"

# Assign self the 'Azure Event Hubs Data Owner' role.
echo "Assigning the 'Azure Event Hubs Data Owner' role to $ASSIGNEE_ID"
az role assignment create \
    --role "$EVENT_HUBS_DATA_OWNER_ROLE_ID" \
    --assignee "$ASSIGNEE_ID" \
    --scope "$EVENT_HUBS_NAMESPACE_ID"