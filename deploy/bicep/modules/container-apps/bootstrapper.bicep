param containerAppsEnvName string
param location string
param sqlConnectionString string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: containerAppsEnvName
}

resource bootstrapper 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'bootstrapper'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'bootstrapper'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-bootstrapper:latest'
          env: [
            {
              name: 'reddog-sql'
              secretRef: 'reddog-sql'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
      }
      dapr: {
        enabled: true
        appId: 'bootstrapper'
      }
    }
    configuration: {
      secrets: [
        {
          name: 'reddog-sql'
          value: sqlConnectionString
        }
      ]
    }
  }
}
