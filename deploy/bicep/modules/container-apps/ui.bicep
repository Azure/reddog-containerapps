param containerAppsEnvName string
param location string
param defaultDomain string
param ingressSubdomain string

resource cappsEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: containerAppsEnvName
}

resource ui 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'ui'
  location: location
  properties: {
    kubeEnvironmentId: cappsEnv.id
    template: {
      containers: [
        {
          name: 'ui'
          image: 'ghcr.io/azure/reddog-retail-demo/reddog-retail-ui:latest'
          env: [
            {
              name: 'VUE_APP_IS_CORP'
              value: 'false'
            }
            {
              name: 'VUE_APP_STORE_ID'
              value: 'Redmond'
            }
            {
              name: 'VUE_APP_SITE_TYPE'
              value: 'Pharmacy'
            }
            {
              name: 'VUE_APP_SITE_TITLE'
              value: 'Red Dog Bodega :: Market fresh food, pharmaceuticals, and fireworks!'
            }
            {
              name: 'VUE_APP_MAKELINE_BASE_URL'
              value: 'http://make-line-service.internal.${defaultDomain}'
            }
            {
              name: 'VUE_APP_ACCOUNTING_BASE_URL'  
              value: 'http://accounting-service.internal.${defaultDomain}'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
      }
      dapr: {
        enabled: false
      }
    }
    configuration: {
      ingress: {
        external: false
        targetPort: 8080
      }
    }
  }
}
