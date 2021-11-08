param cappsEnvName string = 'cappsenv-reddog'
param location string = 'canadacentral'

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: cappsEnvName
}

resource loyalty_service 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'virtual-customer'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'virtual-customer'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-virtual-customers:latest'
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'virtual-customer'
        appPort: 80
        components: []
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
