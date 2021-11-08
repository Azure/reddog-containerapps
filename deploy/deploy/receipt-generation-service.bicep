param cappsEnvName string = 'cappsenv-reddog'
param location string = 'canadacentral'

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: cappsEnvName
}

resource order_service 'Microsoft.Web/containerApps@2021-03-01' = {
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
        minReplicas: 1
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
                value: 'vigilantesblobstorage'
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
        external: true
        targetPort: 80
      }
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: ''
        }
        {
          name: 'blob-storage-key'
          value: ''
        }
      ]
    }
  }
}
