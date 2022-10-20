param containerAppsEnvName string
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

resource cappsEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'reddog.binding.receipt'
  parent: cappsEnv
  properties: {
    componentType: 'bindings.azure.blobstorage'
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
    secrets: [
      {
        name: 'blob-storage-key'
        value: storageAccount.listKeys().keys[0].value
      }
    ]
    scopes: [
      'receipt-generation-service'
    ]
  }
}
