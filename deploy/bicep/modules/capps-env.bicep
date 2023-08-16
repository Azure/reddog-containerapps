param containerAppsEnvName string
param logAnalyticsWorkspaceName string
param appInsightsName string
param location string
param vnetSubnetId string
param vnetInternal bool
param workloadProfileName string
param workloadProfileType string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
  }
}

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: containerAppsEnvName
  location: location

  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: ((!empty(vnetSubnetId)) ? vnetSubnetId : null)
      internal: vnetInternal
    }
    workloadProfiles: ((empty(vnetSubnetId)) ? null : [
      {
        minimumCount: 1
        maximumCount: 10
        name: workloadProfileName
        workloadProfileType: workloadProfileType
      }
    ])
    
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

output name string = containerAppsEnv.name
output cappsEnvId string = containerAppsEnv.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output defaultDomain string = containerAppsEnv.properties.defaultDomain
