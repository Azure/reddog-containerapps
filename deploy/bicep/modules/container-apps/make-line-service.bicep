param containerAppsEnvName string
param location string
param sbRootConnectionString string
param redisHost string
param redisSslPort int
param redisPassword string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: containerAppsEnvName
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
                value: '${redisHost}:${redisSslPort}'
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
          value: sbRootConnectionString
        }
        {
          name: 'redis-password'
          value: redisPassword
        }
      ]
    }
  }
}
