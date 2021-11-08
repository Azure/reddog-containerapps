param cappsEnvName string = 'cappsenv-reddog'
param location string = 'canadacentral'

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: cappsEnvName
}

resource loyalty_service 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'virtual-worker'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'virtual-worker'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-virtual-worker:latest'
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
        external: true
        targetPort: 80
      }
    }
  }
}
