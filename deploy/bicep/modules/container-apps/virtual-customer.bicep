param containerAppsEnvName string
param location string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource virtualCustomers 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'virtual-customers'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'virtual-customers'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-virtual-customers:latest'
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'virtual-customers'
      }
    }
  }
}
