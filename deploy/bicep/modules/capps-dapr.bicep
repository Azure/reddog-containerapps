param containerAppsEnvName string
param serviceBusNamespaceName string
param cosmosAccountName string
param cosmosDatabaseName string
param cosmosCollectionName string
param redisName string
param storageAccountName string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' existing = {
  name: cosmosAccountName
}

resource redis 'Microsoft.Cache/redis@2020-12-01' existing = {
  name: redisName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource pubsub 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
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

resource loyalty 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'reddog.state.loyalty'
  parent: cappsEnv
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    metadata: [
      {
        name: 'url'
        value: 'https://${cosmosAccountName}.documents.azure.com:443/'
      }
      {
        name: 'database'
        value: cosmosDatabaseName
      }
      {
        name: 'collection'
        value: cosmosCollectionName
      }
      {
        name: 'masterKey'
        secretRef: 'cosmos-primary-rw-key'
      }
    ]
    scopes: [
      'loyalty-service'
    ]
    secrets: [
      {
        name: 'cosmos-primary-rw-key'
        value: listkeys(cosmosAccount.id, cosmosAccount.apiVersion).primaryMasterKey
      }
    ]
  }
}

resource redisDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'reddog.state.makeline'
  parent: cappsEnv
  properties: {
    componentType: 'state.redis'
    version: 'v1'
    metadata: [
      {
        name: 'redisHost'
        value: '${redis.properties.hostName}:${redis.properties.sslPort}'
      }
      {
        name: 'redisPassword'
        secretRef: 'redis-password'
      }
      {
        name: 'enableTLS'
        value: 'true'
      }
    ]
    scopes: [
      'make-line-service'
    ]
    secrets: [
      {
        name: 'redis-password'
        value: listKeys(redis.id, redis.apiVersion).primaryKey
      }
    ]
  }
}

resource receipt 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'reddog.binding.receipt'
  parent: cappsEnv
  properties: {
    componentType: 'bindings.azure.blobstorage'
    version: 'v1'
    metadata: [
      {
        name: 'storageAccount'
        value: storageAccountName
      }
      {
        name: 'container'
        value: 'receipts'
      }
      {
        name: 'storageAccessKey'
        secretRef: 'blob-storage-key'
      }
    ]
    scopes: [
      'receipt-generation-service'
    ]
    secrets: [
      {
        name: 'blob-storage-key'
        value: listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
      }
    ]
  }
}

resource orders 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'orders'
  parent: cappsEnv
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    metadata: [
      {
        name: 'schedule'
        value: '@every 15s'
      }
    ]
    scopes: [
      'virtual-worker'
    ]
  }
}
