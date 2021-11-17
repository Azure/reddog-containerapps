param containerAppsEnvName string
param location string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: containerAppsEnvName
}

resource loyaltyService 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'traefik'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'traefik'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-traefik:latest'
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: false
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
