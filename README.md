# Getting hands-on with Azure Container Apps

## Background

[Azure Container Apps](https://azure.microsoft.com/en-gb/services/container-apps/) became generally available in May this year, and since then we've seen a steady increase in interest from customers. It is a fully managed serverless platform for customers to run their containerised apps. 

ACA is built on top of Kubernetes but does not expose the complexities of Kubernetes, so customers can get their applications up and running faster. Customers do not need to understand Kubernetes concepts such as clusters, namespaces, secrets, config maps, or node pools. Nor do they need to worry about constantly upgrading Kubernetes and patching the nodes running their apps.

This repository leverages the [Reddog codebase](https://github.com/Azure/reddog-code) to deploy a multi-service application, and makes use of the [Distributed Application Runtime (Dapr)](https://dapr.io/) for inter-service communication. Dapr is an open source project that helps developers with the inherent challenges presented by distributed applications, such as state management and service invocation.

Container Apps also provides a managed version of [Kubernetes Event Driven Autoscaling (KEDA)](https://keda.sh/), which allows your containers to autoscale based on incoming events from external services such Azure Service Bus and Redis.

To explore how Azure Container Apps compares to other container hosting options in Azure, see [Comparing Container Apps with other Azure container options](https://learn.microsoft.com/en-gb/azure/container-apps/compare-options). 

## Architecture

The architecture is comprised of a single Container Apps Environment that hosts ten .NET Core microservice applications. The .NET Core Dapr SDK is used to integrate with Azure resources through PubSub, State and Binding building blocks and while Dapr typically provides flexibility around the component implementations, this solution is opinionated. The services also make use of KEDA scale rules to allow for scaling based on event triggers as well as scale to zero scenarios.

![Architecture diagram](assets/reddog-containerapps.png)

This repository leverages bicep templates in order to execute the deployment of the application and the supporting Azure Infrastructure. Bicep is a Domain Specific Language (DSL) for deploying Azure resources declaratively and provides a transparent abstraction over Azure Resource Manager (ARM) and ARM templates.

### Container Apps 

For details on the microservices and their functionality, visit the Reddog [codebase repo](https://github.com/Azure/reddog-code). Each Container Apps deployment configuration is described below including its associated Dapr components and KEDA scale rules. Please note this repository contains an additional component that is needed to get the solution up and running on Container Apps.

#### Traefik 

Traefik is a leading reverse proxy and load balancer that integrates with your existing infrastructure components and configures itself automatically. The UI container app has the ability to route to backend container apps through the managed ingress capabilities (Envoy) built into the platform. For this solution, we chose to leverage Traefik's dynamic configuration feature to provide a single point of ingress and a way to invoke internal, back-end apis using the [rest-samples](./rest-samples). The alternative approach would be to enable external ingress on multiple container apps in the environment. Traefik is not necessary for all Container Apps ingress configurations but enables sub-domain routing capabilities which are not supported in the service today, as all container apps in the environment are deployed to a single domain.


| Service          | Ingress |  Dapr Component(s) | KEDA Scale Rule(s) |
|------------------|---------|--------------------|--------------------|
| Traefik | External | Dapr not enabled | HTTP |
| UI | Internal | Dapr not enabled | HTTP |
| Virtual Customer | None | Service to Service Invocation | N/A |
| Order Service | Internal | PubSub: Azure Service Bus | HTTP |
| Accounting Service | Internal | PubSub: Azure Service Bus | Azure Service Bus Subscription Length, HTTP |
| Receipt Service | Internal | PubSub: Azure Service Bus, Binding: Azure Blob | Azure Service Bus Subscription Length |
| Loyalty Service | Internal | PubSub: Azure Service Bus, State: Azure Cosmos DB | Azure Service Bus Subscription Length |
| Makeline Service | Internal | PubSub: Azure Service Bus, State: Azure Redis | Azure Service Bus Subscription Length, HTTP |
| Virtual Worker | None | Service to Service Invocation, Binding: Cron | N/A |

> A tenth service, Bootstrapper is also executed in a Container App. This service is run once to perform the database creation and is subsequently scaled to 0 after creating the necessary objects in Azure SQL Database.

## Standard Deployment

To deploy the Reddog services along with the necessary Azure Resources, clone this repo and run the following [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) commands. You will need an Azure subscription where you have permission to create a Resource Group (e.g. Contributor). Alternatively you may execute the [deploy.sh](./deploy.sh) script.

> Please note that Container Apps is only available in [a subset of Azure regions](https://azure.microsoft.com/en-ca/explore/global-infrastructure/products-by-region/?products=container-apps). 


```bash
# *nix only
export RG="reddog"
export LOCATION="westeurope"
export SUB_ID="<YourSubscriptionID>"

# Follow Azure CLI prompts to authenticate to the subscription of your choice
az login
az account set --subscription $SUB_ID

# Create resource group
az group create -n $RG -l $LOCATION

# Deploy infrastructure and reddog apps
az deployment group create -n reddog -g $RG -f ./deploy/bicep/main.bicep

# Display outputs from bicep deployment
az deployment group show -n reddog -g $RG -o json --query properties.outputs.urls.value
```

To check the status of the deployment while it is running navigate to the `Deployments` blade on the Resource Group in the Azure Portal. Deployment should take ~25 minutes and once completed, you should receive an output similar to the following.

```bash
[
  "UI: https://reddog.whitebush-a2e52ffc.eastus2.azurecontainerapps.io",
  "Product: https://reddog.whitebush-a2e52ffc.eastus2.azurecontainerapps.io/product",
  "Makeline Orders (Redmond): https://reddog.whitebush-a2e52ffc.eastus2.azurecontainerapps.io/makeline/orders/Redmond",
  "Accounting Order Metrics (Redmond): https://reddog.whitebush-a2e52ffc.eastus2.azurecontainerapps.io/accounting/OrderMetrics?StoreId=Redmond"
]
```

Navigate to the fqdn of the UI to see the Reddog solution up and running on Container Apps! 

### Exploring the Deployment

After the deployment has completed, open the FQDN of the front-end UI and leave it open in your browser for a few minutes, which will allow all elements of the UI to populate.

While this is happening, spend some time using the Portal to explore all of the resources that have been deployed into the resource group, and make sure you understand what each component is for.

Try asking yourself a few questions:

1. What is each component used for? What would break/change if this component wasn't deployed?
2. Can you find a "map" of the services and how they connect together? What information is available on this map?
3. How is Dapr used to connect the microservices together? Can you change the Dapr configuration to change the behaviour of the app?
4. Are there any secrets being used as part of the application? If so, where are they being stored?
5. Is there any way to identify if container apps are running on or making use of the same underlying infrastructure?
6. Are you able to force the application to scale up? If so, what did you have to do, and what impact did it have on the application?
7. What monitoring and observability tools do you get "out of the box"? What kind of metrics or other data do you have access to with these tools?
8. What is the default ingress resource being used by the application? Would it be possible to switch this out with something like Nginx?
9. Are you able to find an overview of your entire application in ACA? Can you create or configure an "operational overview" dashboard?
10. Can you access the logs from your containers to see if there are any issues in your app?
11. Is your application performing well? How can you tell?
12. How much is your application costing to run on ACA? Where can you find this information?

## Team Discussions

In your table groups, choose one or more of the [Discussion Topics](#discussion-topics) from below, and talk about them in your groups. 

### Icebreakers

If you want to get to know the rest of your team before starting on the main discussions, try one or more of these icebreakers to get the conversation started.

- "Have you worked with a customer who wanted a more opinionated platform to run their container workloads on?"
- "Have you worked with a customer who *'needed'* Kubernetes, but struggled with the associated complexities and upskilling?
- "Have you worked with a custsomer who expressed a strong preference for ACA or AKS over the other? What was the logic behind their reasoning?"

### Discussion Topics

1. What assets would you have to create to replicate this deployment onto AKS? How could you replicate the "one stop deployment" mechanism we've seen with this Reddog demo?
2. What are the advantages of running full Kubernetes in AKS vs Azure Container Apps (which is built on top of AKS but abstracts most of the features and complexities away)?
3. What are the advantages of running ACA instead of AKS? What's the benefit of using Kubernetes under the hood if all the Kubernetes concepts and features are abstracted away?
4. When might you position one of ACA or AKS over the other during a customer conversation?

## Delete the Deployment

Clean up the deployment by deleting the single resource group that contains the Reddog infrastructure.

> Warning: If you deployed additional resources inside the `reddog` Resource Group, the following command will delete all of them.

```bash
# *nix only
export RG="reddog"

az group delete --name $RG --yes --no-wait
```
