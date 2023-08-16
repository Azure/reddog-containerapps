param containerAppsEnvName string
param location string
param serviceBusNamespaceName string
param workloadProfileName string

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource serviceBusAuthRules 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' existing = {
  name: 'RootManageSharedAccessKey'
  parent: serviceBus
}

resource receiptGenerationService 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'receipt-generation-service'
  location: location
  properties: {
    managedEnvironmentId: cappsEnv.id
    workloadProfileName: workloadProfileName
    template: {
      containers: [
        {
          name: 'receipt-generation-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-receipt-generation-service:latest'
          probes: [
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
                subscriptionName: 'receipt-generation-service'
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
        ]
      }
    }
    configuration: {
      dapr: {
        enabled: true
        appId: 'receipt-generation-service'
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
          value: serviceBusAuthRules.listKeys().primaryConnectionString
        }
      ]
    }
  }
}
