param storageAccountName string
param blobContainerName string
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  
  resource blobService 'blobServices' = {
    name: 'default'
    
    resource blobContainer 'containers' = {
      name: blobContainerName
    }
  }
}

output name string = storageAccount.name
