param cappsEnvName string = 'cappsenv-reddog'
param location string = 'canadacentral'
resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: cappsEnvName
}

resource loyalty_service 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'loyalty-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'loyalty-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-loyalty-service:latest'
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'loyalty-service'
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
            name: 'reddog.state.loyalty'
            type: 'state.azure.cosmosdb'
            version: 'v1'
            metadata: [
              {
                name: 'url'
                value: 'https://vigilantescosmosdb.documents.azure.com:443/'
              }
              {
                name: 'database'
                value: 'daprworkshop'
              }
              {
                name: 'collection'
                value: 'loyalty'
              }
              {
                name: 'masterKey'
                secretRef: 'cosmos-primary-rw-key'
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
          name: 'cosmos-primary-rw-key'
          value: ''
        }
      ]
    }
  }
}
