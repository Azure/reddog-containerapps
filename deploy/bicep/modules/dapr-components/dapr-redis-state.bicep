param containerAppsEnvName string
param serviceBusNamespaceName string
param redisName string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource redis 'Microsoft.Cache/redis@2020-12-01' existing = {
  name: redisName
}

resource redisDaprStateComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
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
      'virtual-workers'
    ]
    secrets: [
      {
        name: 'redis-password'
        value: listKeys(redis.id, redis.apiVersion).primaryKey
      }
    ]
  }
}
