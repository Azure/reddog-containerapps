param containerAppsEnvName string
param serviceBusNamespaceName string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource serviceBusAuthRules 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' existing = {
  name: 'RootManageSharedAccessKey'
  parent: serviceBus
}

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'reddog.pubsub'
  parent: cappsEnv
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'sb-root-connectionstring'
      }
    ]
    secrets: [
      {
        name: 'sb-root-connectionstring'
        value: serviceBusAuthRules.listKeys().primaryConnectionString
      }
    ]
    scopes: [
      'accounting-service'
      'loyalty-service'
      'make-line-service'
      'order-service'
      'receipt-generation-service'
    ]
  }
}
