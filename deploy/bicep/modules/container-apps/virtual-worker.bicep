param containerAppsEnvName string
param location string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource virtualWorker 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'virtual-worker'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'virtual-worker'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-virtual-worker:latest'
          env: [
            {
              name: 'MIN_SECONDS_TO_COMPLETE_ITEM'
              value: '0'
            }
            {
              name: 'MAX_SECONDS_TO_COMPLETE_ITEM'
              value: '1'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
    configuration: {
      dapr: {
        enabled: true
        appId: 'virtual-worker'
        appPort: 80
      }
      ingress: {
        external: false
        targetPort: 80
      }
    }
  }
}
