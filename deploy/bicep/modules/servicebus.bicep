param serviceBusNamespaceName string
param location string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
}

output namespaceName string = serviceBus.name
