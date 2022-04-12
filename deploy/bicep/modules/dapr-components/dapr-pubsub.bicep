param containerAppsEnvName string
param serviceBusNamespaceName string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource daprPubSubComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
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
    scopes: [
      'virtual-worker'
      'accounting-service'
      'loyalty-service'
      'make-line-service'
      'order-service'
      'receipt-generation-service'
    ]
    secrets: [
      {
        name: 'sb-root-connectionstring'
        value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
      }
    ]
  }
}
