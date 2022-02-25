param redisName string
param location string

resource redis 'Microsoft.Cache/redis@2020-12-01' = {
  name: redisName
  location: location
  properties: {
    sku: {
      name: 'Standard'
      family: 'C'
      capacity: 1
    }
    enableNonSslPort: false
  }
}
