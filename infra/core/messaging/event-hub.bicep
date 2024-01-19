param name string

param eventHubNamespaceName string
param partitionCount int = 1
param retentionInDays int = 1
param consumerGroupName string = ''

resource namespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubNamespaceName
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  name: name
  parent: namespace
  properties: {
    partitionCount: partitionCount
    messageRetentionInDays: retentionInDays
  }

  resource consumerGroup 'consumergroups' = if (!empty(consumerGroupName)) {
    name: consumerGroupName
  }
}

output EventHubName string = eventHub.name
output EventHubConsumerGroupName string = eventHub::consumerGroup.name
