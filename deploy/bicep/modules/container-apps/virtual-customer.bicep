param containerAppsEnvName string
param location string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-03-01' existing = {
  name: containerAppsEnvName
}

resource virtualCustomers 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'virtual-customers'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'virtual-customers'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-virtual-customers:latest'
          env: [
            {
              name: 'STORE_ID'
              value: 'Denver'
            }
            {
              name: 'MAX_ITEM_QUANTITY'
              value: '9'
            }
            {
              name: 'MIN_SEC_TO_PLACE_ORDER'
              value: '2'
            }
            {
              name: 'MAX_SEC_TO_PLACE_ORDER'
              value: '8'
            }
            {
              name: 'MIN_SEC_BETWEEN_ORDERS'
              value: '2'
            }
            {
              name: 'MAX_SEC_BETWEEN_ORDERS'  
              value: '8'
            }
            {
              name: 'NUM_ORDERS'  
              value: '-1'
            }            
          ]          
        }
      ]
      scale: {
        minReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'virtual-customers'
      }
    }
  }
}
