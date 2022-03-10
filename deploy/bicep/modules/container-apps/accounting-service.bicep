param containerAppsEnvName string
param location string
param serviceBusNamespaceName string
param sqlServerName string
param sqlDatabaseName string
param sqlAdminLogin string
param sqlAdminLoginPassword string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-03-01' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource accountingService 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'accounting-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'accounting-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-accounting-service:latest'
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
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                topicName: 'orders'
                subscriptionName: 'accounting-service'
                messageCount: '10'
              }
              auth: [
                {
                  secretRef: 'sb-root-connectionstring'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
          {
            name: 'http-rule'
            http: {
              metadata: {
                  concurrentRequests: '100'
              }
            }
          }
        ]
      }
      dapr: {
        enabled: true
        appId: 'accounting-service'
        appPort: 80
        components: [
          {
            name: 'reddog.pubsub'
            type: 'pubsub.azure.servicebus'
            version: 'v1'
            metadata: [
              {
                name: 'connectionString'
                secretRef: 'sb-root-connectionstring'
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
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
        }
        {
          name: 'reddog-sql'
          value: 'Server=tcp:${sqlServerName}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
      ]
    }
  }
}
