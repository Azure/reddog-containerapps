param containerAppsEnvName string
param location string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource orderService 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'order-service'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'order-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-order-service:latest'
        }
      ]
      scale: {
        minReplicas: 0
      }
    }
    configuration: {
      ingress: {
        external: false
        targetPort: 80
      }
      dapr: {
        enabled: true
        appId: 'order-service'
        appPort: 80
      }
    }
  }
}
