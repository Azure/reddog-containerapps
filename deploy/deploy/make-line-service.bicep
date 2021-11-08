param cappsEnvName string = 'cappsenv-reddog'
param location string = 'canadacentral'

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: cappsEnvName
}

resource order_service 'Microsoft.Web/containerApps@2021-03-01' = {
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
        minReplicas: 1
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
                value: 'vigilantes-redis.redis.cache.windows.net:6379'
              }
              {
                name: 'redisPassword'
                secretRef: 'redis-password'
              }
            ]
          }
        ]
      }
    }
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: ''
        }
        {
          name: 'redis-password'
          value: ''
        }
      ]
    }
  }
}
