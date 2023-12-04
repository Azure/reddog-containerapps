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

To deploy the Reddog services along with the necessary Azure Resources, clone this repo and run the following [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) commands. You will need an Azure subscription where you have permission to create a Resource Group (e.g. Contributor). Alternatively you may execute the [deploy.sh](./deploy.sh) or [deploy.ps1](./deploy.ps1) script.

> Please note that Container Apps is only available in [a subset of Azure regions](https://azure.microsoft.com/en-ca/explore/global-infrastructure/products-by-region/?products=container-apps). 


```bash
# *nix bash                            # Windows PowerShell
export RG="reddog"                     # $RG="reddog"
export LOCATION="westeurope"           # $LOCATION="westeurope"
export SUB_ID="<YourSubscriptionID>"   # $SUB_ID="<YourSubscriptionID>"

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
13. Let's try to secure our service to service communication by enabling service wide MTLS. How can we jusdge whether this has impacted performance? 
14. Reflect on usage of DAPR, Secret Stores, Service intergration and MTLS. What would be required to configure these services on AKS?
15. Is our application highly available? How does high availability differ between AKS and ACA?

### Guided Activity - Blue/Green deployments in ACA

We will now use the portal to take a look at how we can implement blue/green deployments out of the box with Azure Container Apps. While we go through this activity, think about how this differs operationally when compared to AKS.

1. To begin with let's create a brand new container app and container app environment. First lest navigate to the Container Apps service.
<br/><br/>
<img width="1196" alt="Container apps dashboard" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/022d763b-4bcb-44ff-aa34-8181407d74a9">
<br/><br/>
    
2. Lets create a new container app in the same resource group with the name blue-green-demo. Select your region and before creating lets also create a new container apps environment by clicking "create new".
<br/><br/>   
<img width="1200" alt="create container app" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/427ffb14-eb47-4a45-9c89-cc2fde4c8ab3">
<br/><br/>
     
3. Lets give the environment a new name and then select workload profiles as the environment type and enable zone redundancy. Next click on workload profiles and review the consumption profile. There is no next button on the portal here so dont press create yet, navigate through the options using the menus at the top.
<br/><br/>
<img width="1169" alt="Create container apps env" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/474631a0-e040-4b44-849e-99a7bb392e0b">
<br/><br/>
   
Review the available profiles & pick a new profile to add to your environment. When   creating the profile set an autoscale min of 3 and a maximum of 5. This is because we are going to use a small subnet and the ACA-E will fail to create if the maximum scale for a profile surpases the IP addresses available in the subnet. 
  
Next review the monitoring options. We can leave this at default for the moment. 

Finally let's deploy this environment in our own VNET by creatig a new VNET and SUBNET. As we know from earlier this is required for high availability. When creating a VNET in the portal we are not able to change the IP range. Let's then create a new /27 subnet. This is the smallest subnet we can use for a container apps environment. We can then select an external virtual IP to allow for public connections to our container apps (when we specify it).
<br/><br/>  
  <img width="1199" alt="acae-subnet" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/7461a52b-70e9-4c02-8d37-3e78c5b66388">
<br/><br/>


4. Once the environment is created we can then press next and begin to configure our container apps container. We are going to use a public docker hub image "scubakiz/servicedemo:1.0" for this demo. We can leave the other feilds here as is. See the screenshot for the config if you are unsure. Select the new workload profile you created when deploying the container. You are able to set the containers resource limits as you would in a dockerfile through the portal here. Finally we will add a single enviroment variable called "IMAGE_COLOR" with a value of "green".
<br/><br/>
<img width="835" alt="configure container app container" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/5dc03991-f378-49ac-a5bf-c9b3d5afa2ad">
<br/><br/>

5. We do not require any bindings for this application so we can skip that for now and then on the following screen tick the box to enable ingress. Once selected we can change the ingress traffic setting to accept traffic from anywhere and set the target port to 80.
<br/><br/>
<img width="1200" alt="configure container apps ingress" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/35bfed97-d061-4ddf-b269-9bd251ea5433">
<br/><br/>

6. Once your deployment is validated we can then create our container app by clicking create.

7. Once your container app is created click through and check the app is running as expected by clicking the app URL in the overview.

8. Once we have validated the app is running its time to create another version and do some blue green testing. First we need to change the revision mode. We can do this by clicking revision mode in the revisions blade.
<br/><br/>
<img width="938" alt="single-to-multi-revisions" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/447c6a4a-4790-4920-b0c7-a77ca77805d3">
<br/><br/>

9. Next we need to click "Create new revision". Once here we can see our existing contianer images in our container app. Select the existing image we are using. We can then click the image and make a change. In this case we are going to change the environment variable we added. Change the value from green to blue and save the new revision. You will see the new revision being deployed in the revisions portal.
<br/><br/>
<img width="1197" alt="create blue revision" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/f0dd5c38-6f67-421c-bfb5-78406e6a49c9">
<br/><br/>

  While the traffic is at 0 we are provided a revision specific url. This allows us to take a look at our revision and validate our changes. Select the new revision and validate the image is now blue. 
<br/><br/>
<img width="1200" alt="blue-revision-pre-traffic-split" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/4990e594-78a8-466d-87d6-fcfd8e1fc982">
<br/><br/>
     
  Once validated we can then go into our traffic splitting and set both revisions to 50%. Once set save the change.

10. Go back to the container app URL. The application refreshes itself every few seconds. You will notice you are now being served the two different applications. 
<br/><br/>
<img width="914" alt="blue app" src="https://github.com/pjlewisuk/reddog-containerapps/assets/48108258/9b5268c8-f464-49b0-aa85-e48ceb7537ff">
<br/><br/>
  
  Note the other information on the application is not working. This information uses the Kubernetes downward API and needs to be specified as a feildRef: in the manifest file when deploying to Kuberenetes. This is not supported in ACA at the moment. 

  Would blue/green deployments be this easy on AKS? What does the lack of support for setting downward api env vars highlight?

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
