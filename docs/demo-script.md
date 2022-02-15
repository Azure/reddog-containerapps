## Demo Script

#### Basics

* Docs. https://docs.microsoft.com/en-us/azure/container-apps 
* Red Dog repo. https://github.com/Azure/reddog-code
* Show UI
* VS Code. Show Bicep files
* Portal
    * Secrets (accounting-service)
    * Ingress
    * Continuous deployment
* Logging (iTerm)

```bash
export RG=''
export LOG_ANALYTICS_WORKSPACE=''
export LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az monitor log-analytics workspace show --query customerId -g $RG -n $LOG_ANALYTICS_WORKSPACE --out tsv`

az monitor log-analytics query \
  --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'virtual-customers' | project ContainerAppName_s, Log_s, TimeGenerated " \
  --out table

az monitor log-analytics query \
  --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'make-line-service' | project ContainerAppName_s, Log_s, TimeGenerated | take 10" \
  --out table
```

#### Autoscaling

* Kick off load test in Portal
* Show replica counts in iTerm window

```bash
# open 4 terminal windows

export RG=''
watch az containerapp revision list --name order-service --resource-group $RG

export RG=''
watch az containerapp revision list --name make-line-service --resource-group $RG

export RG=''
watch az containerapp revision list --name accounting-service --resource-group $RG

export RG=''
watch az containerapp revision list --name loyalty-service --resource-group $RG
```

* Show Azure Load Testing Service details and jmeter
* Show scaled container apps
* Show autoscale config in Bicep files
    * HTTP (order-service)
    * Queue-based (accounting-service)
* Show Azure Load Testing graph results of prior test
* Show JMeter output graphs

#### Revisions and Traffic Shaping (Inventory Service)

> Note: Need to update this section with a container app revision

* Deploy a new revision and show

```bash
export RG=''
az containerapp revision list --name some-service --resource-group $RG
```

* Show some-service in portal with 20/80
* Show output

```bash
while true; do curl https://some-service.kindpebble-5d9795f7.eastus.azurecontainerapps.io/inventorybyid?id=3 && echo '' ; sleep 1; done
```

* Change to 90% on v2
* Show Revisions in Portal
* Show output change 

#### Dapr

* Show accounting-service, receipt-generation-service
* Explain Hybrid Red Dog and how bindings are different in Corp and Branch
* Show Bicep config in VS Code
* Show Dapr source code. https://github.com/Azure/reddog-code/blob/master/RedDog.VirtualCustomers/VirtualCustomers.cs#L332 
* App Insights - Portal
  * Drill into details