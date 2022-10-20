param sqlServerName string
param sqlDatabaseName string
param location string
param sqlAdminLogin string

@secure()
param sqlAdminLoginPassword string

resource sqlserver 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminLoginPassword
  }
  
  resource sqlfirewall 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
  
  resource database 'databases' = {
    name: sqlDatabaseName
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
}

output serverName string = sqlserver.name
