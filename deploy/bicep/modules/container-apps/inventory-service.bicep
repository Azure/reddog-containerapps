param containerAppsEnvName string
param location string
param inventoryImage string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-03-01' existing = {
  name: containerAppsEnvName
}

resource inventoryContainerApp 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'inventory-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'inventory-service'
          image: inventoryImage
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'inventory-service'
      }
    }
    configuration: {
      ingress: {
        external: true
        targetPort: 8081
      }
    }
  }
}

output fqdn string = inventoryContainerApp.properties.configuration.ingress.fqdn
