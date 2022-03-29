param location string = resourceGroup().location
param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param uniqueSuffix string = 'reddog-${uniqueString(uniqueSeed)}'
param containerAppsEnvName string = 'cae-${uniqueSuffix}'
param logAnalyticsWorkspaceName string = 'log-${uniqueSuffix}'
param appInsightsName string = 'appi-${uniqueSuffix}'
param serviceBusNamespaceName string = 'sb-${uniqueSuffix}'
param redisName string = 'redis-${uniqueSuffix}'
param cosmosAccountName string = 'cosmos-${uniqueSuffix}'
param cosmosDatabaseName string = 'reddog'
param cosmosCollectionName string = 'loyalty'
param storageAccountName string = 'st${replace(uniqueSuffix, '-', '')}'
param blobContainerName string = 'receipts'
param sqlServerName string = 'sql-${uniqueSuffix}'
param sqlDatabaseName string = 'reddog'
param sqlAdminLogin string = 'reddog'
param sqlAdminLoginPassword string = take(newGuid(), 16)

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

module daprBindingReceipt 'modules/dapr-components/binding-receipt.bicep' = {
  name: '${deployment().name}--dapr-binding-receipt'
  dependsOn: [
    containerAppsEnvModule
    storageModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    storageAccountName: storageAccountName
  }
}

module daprBindingVirtualWorker 'modules/dapr-components/binding-virtualworker.bicep' = {
  name: '${deployment().name}--dapr-binding-virtualworker'
  dependsOn: [
    containerAppsEnvModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
  }
}

module daprPubsub 'modules/dapr-components/pubsub.bicep' = {
  name: '${deployment().name}--dapr-pubsub'
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module daprStateLoyalty 'modules/dapr-components/state-loyalty.bicep' = {
  name: '${deployment().name}--dapr-state-loyalty'
  dependsOn: [
    containerAppsEnvModule
    cosmosModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    cosmosAccountName: cosmosAccountName
    cosmosDatabaseName: cosmosDatabaseName
    cosmosCollectionName: cosmosCollectionName
  }
}

module daprStateMakeline 'modules/dapr-components/state-makeline.bicep' = {
  name: '${deployment().name}--dapr-state-makeline'
  dependsOn: [
    containerAppsEnvModule
    redisModule
  ]
  params: {
    containerAppsEnvName: containerAppsEnvName
    redisName: redisName
  }
}

module orderServiceModule 'modules/container-apps/order-service.bicep' = {
  name: '${deployment().name}--order-service'
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    daprPubsub
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
  }
}

module makeLineServiceModule 'modules/container-apps/make-line-service.bicep' = {
  name: '${deployment().name}--make-line-service'
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    redisModule
    daprPubsub
    daprStateMakeline
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module loyaltyServiceModule 'modules/container-apps/loyalty-service.bicep' = {
  name: '${deployment().name}--loyalty-service'
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    daprPubsub
    daprStateLoyalty
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module receiptGenerationServiceModule 'modules/container-apps/receipt-generation-service.bicep' = {
  name: '${deployment().name}--receipt-generation-service'
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    daprBindingReceipt
    daprPubsub
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module virtualWorkerModule 'modules/container-apps/virtual-worker.bicep' = {
  name: '${deployment().name}--virtual-worker'
  dependsOn: [
    containerAppsEnvModule
    makeLineServiceModule
    daprBindingVirtualWorker
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
    sqlServerModule
    orderServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    sqlDatabaseName: sqlDatabaseName
    sqlServerName: sqlServerName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminLoginPassword: sqlAdminLoginPassword
  }
}

module accountingServiceModule 'modules/container-apps/accounting-service.bicep' = {
  name: '${deployment().name}--accounting-service'
  dependsOn: [
    containerAppsEnvModule
    serviceBusModule
    sqlServerModule
    bootstrapperModule
    daprPubsub
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    serviceBusNamespaceName: serviceBusNamespaceName
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminLoginPassword: sqlAdminLoginPassword
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

output urls array = [
  'UI: https://reddog.${containerAppsEnvModule.outputs.defaultDomain}'
  'Product: https://reddog.${containerAppsEnvModule.outputs.defaultDomain}/product'
  'Makeline Orders (Redmond): https://reddog.${containerAppsEnvModule.outputs.defaultDomain}/makeline/orders/Redmond'
  'Accounting Order Metrics (Redmond): https://reddog.${containerAppsEnvModule.outputs.defaultDomain}/accounting/OrderMetrics?StoreId=Redmond'
]
