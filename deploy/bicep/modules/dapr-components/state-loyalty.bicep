param containerAppsEnvName string
param cosmosAccountName string
param cosmosDatabaseName string
param cosmosCollectionName string

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosAccountName
}

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'reddog.state.loyalty'
  parent: cappsEnv
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    metadata: [
      {
        name: 'url'
        value: cosmosAccount.properties.documentEndpoint
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
    secrets: [
      {
        name: 'cosmos-primary-rw-key'
        value: cosmosAccount.listKeys().primaryMasterKey
      }
    ]
    scopes: [
      'loyalty-service'
    ]
  }
}
