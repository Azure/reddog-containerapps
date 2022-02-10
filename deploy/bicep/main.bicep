param location string = resourceGroup().location
param containerAppsEnvName string = resourceGroup().location
param logAnalyticsWorkspaceName string = resourceGroup().location
param appInsightsName string = resourceGroup().location
param serviceBusNamespaceName string = resourceGroup().location
param redisName string = resourceGroup().location
param cosmosAccountName string = resourceGroup().location
param cosmosDatabaseName string = 'daprworkshop'
param cosmosCollectionName string = 'loyalty'
param storageAccountName string = replace(resourceGroup().location, '-', '')
param blobContainerName string = 'receipts'
param sqlServerName string = resourceGroup().location
param sqlDatabaseName string = 'reddog'
param sqlAdminLogin string = 'reddog'
param sqlAdminLoginPassword string = 'w@lkingth3d0g'

module containerAppsEnvModule 'modules/capps-env.bicep' = {
  name: '${deployment().name}--containerAppsEnv'
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
  }
}

module serviceBusModule 'modules/servicebus.bicep' = {
  name: '${deployment().name}--servicebus'
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    location: location
  }
}

module redisModule 'modules/redis.bicep' = {
  name: '${deployment().name}--redis'
  params: {
    redisName: redisName
    location: location
  }
}

module cosmosModule 'modules/cosmos.bicep' = {
  name: '${deployment().name}--cosmos'
  params: {
    cosmosAccountName: cosmosAccountName
    cosmosDatabaseName: cosmosDatabaseName
    cosmosCollectionName: cosmosCollectionName
    location: location
  }
}

module storageModule 'modules/storage.bicep' = {
  name: '${deployment().name}--storage'
  params: {
    storageAccountName: storageAccountName
    blobContainerName: blobContainerName
    location: location
  }
}

module sqlServerModule 'modules/sqlserver.bicep' = {
  name: '${deployment().name}--sqlserver'
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
  dependsOn: [
    containerAppsEnvModule
    makeLineServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}

module bootstrapperModule 'modules/container-apps/bootstrapper.bicep' = {
  name: '${deployment().name}--bootstrapper'
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

module virtualCustomerModule 'modules/container-apps/virtual-customer.bicep' = {
  name: '${deployment().name}--virtual-customer'
  dependsOn: [
    containerAppsEnvModule
    orderServiceModule
    makeLineServiceModule
    receiptGenerationServiceModule
    loyaltyServiceModule
    accountingServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}

module traefikModule 'modules/container-apps/traefik.bicep' = {
  name: '${deployment().name}--traefik'
  dependsOn: [
    containerAppsEnvModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}

module uiModule 'modules/container-apps/ui.bicep' = {
  name: '${deployment().name}--ui'
  dependsOn: [
    containerAppsEnvModule
    makeLineServiceModule
    accountingServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}
