param containerAppsEnvName string
param location string
param serviceBusNamespaceName string
param cosmosAccountName string
param cosmosDatabaseName string
param cosmosCollectionName string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-03-01' existing = {
  name: containerAppsEnvName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' existing = {
  name: cosmosAccountName
}

resource loyaltyService 'Microsoft.Web/containerApps@2021-03-01' = {
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
        minReplicas: 0
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                topicName: 'orders'
                subscriptionName: 'loyalty-service'
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
                value: 'https://${cosmosAccountName}.documents.azure.com:443/'
              }
              {
                name: 'database'
                value: cosmosDatabaseName
              }
              {
                name: 'collection'
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
          value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
        }
        {
          name: 'cosmos-primary-rw-key'
          value: listkeys(cosmosAccount.id, cosmosAccount.apiVersion).primaryMasterKey
        }
      ]
    }
  }
}
