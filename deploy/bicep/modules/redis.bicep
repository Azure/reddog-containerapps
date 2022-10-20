param redisName string
param location string

resource redis 'Microsoft.Cache/redis@2022-06-01' = {
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

output name string = redisName
