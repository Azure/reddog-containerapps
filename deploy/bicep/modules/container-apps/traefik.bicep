param containerAppsEnvName string
param location string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource traefik 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'reddog'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'traefik'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-traefik:latest'
        }
      ]
      scale: {
        minReplicas: 0
      }
    }
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      dapr: {
        enabled: true
        appId: 'traefik'
      }
    }
  }
}

output subdomain string = traefik.name
