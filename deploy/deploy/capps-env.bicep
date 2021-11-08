param cappsEnvName string = 'cappsenv-reddog'
param logAnalyticsWorkspaceName string = 'logs-${cappsEnvName}'
param appInsightsName string = 'appins-${cappsEnvName}'
param location string = 'canadacentral'
param logLocation string = 'Canada Central'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: logLocation
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

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: logLocation
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'CustomDeployment'
  }
}

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' = {
  name: cappsEnvName
  location: location
  kind: 'containerenvironment'
  properties: {
    type: 'managed'
    internalLoadBalancerEnabled: false
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

output cappsEnvId string = cappsEnv.id
