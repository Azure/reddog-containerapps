param containerAppsEnvName string
param location string
param serviceBusNamespaceName string
param redisName string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-03-01' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource redis 'Microsoft.Cache/redis@2020-12-01' existing = {
  name: redisName
}

resource makeLineService 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'make-line-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'make-line-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-make-line-service:latest'
        }
      ]
      scale: {
        minReplicas: 0
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                topicName: 'orders'
                subscriptionName: 'make-line-service'
                messageCount: '10'
              }
              auth: [
                {
                  secretRef: 'sb-root-connectionstring'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
          {
            name: 'http-rule'
            http: {
              metadata: {
                  concurrentRequests: '100'
              }
            }
          }
        ]
      }
      dapr: {
        enabled: true
        appId: 'make-line-service'
        appPort: 80
        components: [
          {
            name: 'reddog.pubsub'
            type: 'pubsub.azure.servicebus'
            version: 'v1'
            metadata: [
              {
                name: 'connectionString'
                secretRef: 'sb-root-connectionstring'
              }
            ]
          }
          {
            name: 'reddog.state.makeline'
            type: 'state.redis'
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
          }
        ]
      }
    }
    configuration: {
      ingress: {
        external: false
        targetPort: 80
      }
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
        }
        {
          name: 'redis-password'
          value: listKeys(redis.id, redis.apiVersion).primaryKey
        }
      ]
    }
  }
}
