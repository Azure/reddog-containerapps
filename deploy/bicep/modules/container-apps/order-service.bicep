param containerAppsEnvName string
param location string
param serviceBusNamespaceName string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-03-01' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource orderService 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'order-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'order-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-order-service:latest'
        }
      ]
      scale: {
        minReplicas: 0
      }
      dapr: {
        enabled: true
        appId: 'order-service'
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
      ]
    }
  }
}
