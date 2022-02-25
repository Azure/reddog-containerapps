param sqlServerName string
param sqlDatabaseName string
param location string
param sqlAdminLogin string
param sqlAdminLoginPassword string

resource sqlserver 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminLoginPassword
  }
}

resource sqlfirewall 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlserver
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: sqlDatabaseName
  parent: sqlserver
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    autoPauseDelay: 60
  }
}
