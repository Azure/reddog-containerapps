param containerAppsEnvName string
param location string
param sbRootConnectionString string
param cosmosUrl string
param cosmosDatabaseName string
param cosmosCollectionName string
param cosmosPrimaryKey string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-03-01' existing = {
  name: containerAppsEnvName
}

resource makeLineService 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'make-line-service'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'make-line-service'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-make-line-service:latest'
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
                subscriptionName: 'make-line-service'
                messageCount: '5'
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
        appId: 'make-line-service'
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
            name: 'reddog.state.makeline'
            type: 'state.azure.cosmosdb'
            version: 'v1'
            metadata: [
              {
                name: 'url'
                // value: 'https://vigilantescosmosdb.documents.azure.com:443/'
                value: cosmosUrl
              }
              {
                name: 'database'
                // value: 'daprworkshop'
                value: cosmosDatabaseName
              }
              {
                name: 'collection'
                // value: 'loyalty'
                value: cosmosCollectionName
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
        external: false
        targetPort: 80
      }
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: sbRootConnectionString
        }
        {
          name: 'cosmos-primary-rw-key'
          value: cosmosPrimaryKey
        }
      ]
    }
  }
}
