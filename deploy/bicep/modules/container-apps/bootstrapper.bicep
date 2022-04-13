param containerAppsEnvName string
param location string
param sqlServerName string
param sqlDatabaseName string
param sqlAdminLogin string
param sqlAdminLoginPassword string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource bootstrapper 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'bootstrapper'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
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
    }
    configuration: {
      dapr: {
        enabled: true
        appId: 'bootstrapper'
        appProtocol: 'http'
      }
      secrets: [
        {
          name: 'reddog-sql'
          value: 'Server=tcp:${sqlServerName}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
      ]
    }
  }
}
