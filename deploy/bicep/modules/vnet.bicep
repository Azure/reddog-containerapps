param virtualNetworkName string
param subnetName string
param location string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/23'
        }
      }
    ]
  }

  resource subnet1 'subnets' existing = {
    name: subnetName
  }
}

output subnet1ResourceId string = virtualNetwork::subnet1.id
