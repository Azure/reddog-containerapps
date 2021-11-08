param cappsEnvName string = 'cappsenv-reddog'
param location string = 'canadacentral'

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: cappsEnvName
}

resource order_service 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'order-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'order-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-order-service:latest'
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'order-service'
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
      ]
    }
  }
}
