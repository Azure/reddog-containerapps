param containerAppsEnvName string
param location string
param sbRootConnectionString string
param storageAccountName string
param blobStorageKey string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: containerAppsEnvName
}

resource receiptGenerationService 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'receipt-generation-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'receipt-generation-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-receipt-generation-service:latest'
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
      dapr: {
        enabled: true
        appId: 'receipt-generation-service'
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
          {
            name: 'reddog.binding.receipt'
            type: 'bindings.azure.blobstorage'
            version: 'v1'
            metadata: [
              {
                name: 'storageAccount'
                value: storageAccountName
              }
              {
                name: 'container'
                value: 'receipts'
              }
              {
                name: 'storageAccessKey'
                secretRef: 'blob-storage-key'
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
          value: sbRootConnectionString
        }
        {
          name: 'blob-storage-key'
          value: blobStorageKey
        }
      ]
    }
  }
}
