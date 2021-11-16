param containerAppsEnvName string
param location string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: containerAppsEnvName
}

resource virtualWorker 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'virtual-worker'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'virtual-worker'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-virtual-worker:latest'
          env: [
            {
              name: 'MIN_SECONDS_TO_COMPLETE_ITEM'
              value: 0
            }
            {
              name: 'MAX_SECONDS_TO_COMPLETE_ITEM'
              value: 1
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'virtual-worker'
        appPort: 80
        components: [
          {
            name: 'orders'
            type: 'bindings.cron'
            version: 'v1'
            metadata: [
              {
                name: 'schedule'
                value: '@every 15s'
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
    }
  }
}
