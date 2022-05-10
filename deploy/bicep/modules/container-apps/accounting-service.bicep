param containerAppsEnvName string
param location string
param serviceBusNamespaceName string
param sqlServerName string
param sqlDatabaseName string
param sqlAdminLogin string
param sqlAdminLoginPassword string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource accountingService 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'accounting-service'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
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
          probes: [
            {
              type: 'readiness'
              httpGet: {
                path: '/probes/ready'
                port: 80
              }
              timeoutSeconds: 30
              successThreshold: 1
              failureThreshold: 10
              periodSeconds: 10
            }
            {
              type: 'startup'
              httpGet: {
                path: '/probes/healthz'
                port: 80
              }
              failureThreshold: 6
              periodSeconds: 10
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
    }
    configuration: {
      dapr: {
        enabled: true
        appId: 'accounting-service'
        appPort: 80
        appProtocol: 'http'
      }
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
