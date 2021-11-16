targetScope = 'subscription'

param location string = deployment().location
param resourceGroupName string = 'rg-reddog'
param containerAppsEnvName string = 'ca-reddog2'
param logAnalyticsWorkspaceName string = 'la-${containerAppsEnvName}'
param appInsightsName string = 'ai-${containerAppsEnvName}'
param serviceBusNamespaceName string = 'sb-${containerAppsEnvName}'
param redisName string = 'r-${containerAppsEnvName}'
param cosmosAccountName string = 'c-${containerAppsEnvName}'
param cosmosDatabaseName string = 'daprworkshop'
param cosmosCollectionName string = 'loyalty'
param storageAccountName string = replace(containerAppsEnvName, '-', '')
param blobContainerName string = 'receipts'
param sqlServerName string = 'sql-reddog'
param sqlDatabaseName string = 'reddog'
param sqlAdminLogin string = 'reddog'
param sqlAdminLoginPassword string = 'w@lkingth3d0g'

module resourceGroupModule 'modules/resource-group.bicep' = {
  name: '${deployment().name}--resourceGroup'
  scope: subscription()
  params: {
    location: location
    resourceGroupName: resourceGroupName
  }
}

module containerAppsEnvModule 'modules/capps-env.bicep' = {
  name: '${deployment().name}--containerAppsEnv'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroupModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
  }
}

module serviceBusModule 'modules/servicebus.bicep' = {
  name: '${deployment().name}--servicebus'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroupModule
  ]
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    location: location
  }
}

module redisModule 'modules/redis.bicep' = {
  name: '${deployment().name}--redis'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroupModule
  ]
  params: {
    redisName: redisName
    location: location
  }
}

module cosmosModule 'modules/cosmos.bicep' = {
  name: '${deployment().name}--cosmos'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroupModule
  ]
  params: {
    cosmosAccountName: cosmosAccountName
    cosmosDatabaseName: cosmosDatabaseName
    cosmosCollectionName: cosmosCollectionName
    location: location
  }
}

module storageModule 'modules/storage.bicep' = {
  name: '${deployment().name}--storage'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroupModule
  ]
  params: {
    storageAccountName: storageAccountName
    blobContainerName: blobContainerName
    location: location
  }
}

module sqlServerModule 'modules/sqlserver.bicep' = {
  name: '${deployment().name}--sqlserver'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroupModule
  ]
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminLoginPassword: sqlAdminLoginPassword
    location: location
  }
}

module orderServiceModule 'modules/container-apps/order-service.bicep' = {
  name: '${deployment().name}--order-service'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sbRootConnectionString: serviceBusModule.outputs.rootConnectionString
  }
}

module makeLineServiceModule 'modules/container-apps/make-line-service.bicep' = {
  name: '${deployment().name}--make-line-service'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sbRootConnectionString: serviceBusModule.outputs.rootConnectionString
    redisHost: redisModule.outputs.redisHost
    redisSslPort: redisModule.outputs.redisSslPort
    redisPassword: redisModule.outputs.redisPassword
  }
}

module loyaltyServiceModule 'modules/container-apps/loyalty-service.bicep' = {
  name: '${deployment().name}--loyalty-service'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sbRootConnectionString: serviceBusModule.outputs.rootConnectionString
    cosmosDatabaseName: cosmosDatabaseName
    cosmosCollectionName: cosmosCollectionName
    cosmosUrl: cosmosModule.outputs.cosmosUri
    cosmosPrimaryKey: cosmosModule.outputs.cosmosPrimaryKey
  }
}

module receiptGenerationServiceModule 'modules/container-apps/receipt-generation-service.bicep' = {
  name: '${deployment().name}--receipt-generation-service'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sbRootConnectionString: serviceBusModule.outputs.rootConnectionString
    storageAccountName: storageAccountName
    blobStorageKey: storageModule.outputs.accessKey
  }
}

module virtualWorkerModule 'modules/container-apps/virtual-worker.bicep' = {
  name: '${deployment().name}--virtual-worker'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
    makeLineServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}

module virtualCustomerModule 'modules/container-apps/virtual-customer.bicep' = {
  name: '${deployment().name}--virtual-customer'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
    orderServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}

module bootstrapperModule 'modules/container-apps/bootstrapper.bicep' = {
  name: '${deployment().name}--bootstrapper'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
    orderServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sqlConnectionString: sqlServerModule.outputs.sqlConnectionString
  }
}

module accountingServiceModule 'modules/container-apps/accounting-service.bicep' = {
  name: '${deployment().name}--accounting-service'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerAppsEnvModule
    bootstrapperModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sbRootConnectionString: serviceBusModule.outputs.rootConnectionString
    sqlConnectionString: sqlServerModule.outputs.sqlConnectionString
  }
}
