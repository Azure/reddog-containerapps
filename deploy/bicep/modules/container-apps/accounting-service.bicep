param containerAppsEnvName string
param location string
param sbRootConnectionString string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: containerAppsEnvName
}

resource accountingService 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'accounting-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'accounting-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-accounting-service:latest'
        }
      ]
      scale: {
        minReplicas: 0
      }
      dapr: {
        enabled: true
        appId: 'accounting-service'
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
        external: false
        targetPort: 80
      }
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: sbRootConnectionString
        }
      ]
    }
  }
}
