# Red Dog Demo - Container Apps Deployment

### Background

This repository leverages the [reddog applicaton codebase](https://github.com/Azure/reddog-code) and was created to help users deploy a comprehensive, microservice-based sample application to Azure Container Apps. 

[Azure Container Apps](https://azure.microsoft.com/en-us/services/container-apps/)* is a fully managed serverless container service for building and deploying modern apps at scale. It enables developers to deploy containerized apps without managing complex infrastructure. The reddog microservices were built using the Distributed Application Runtime (Dapr), which has built-in support via Azure Container Apps. In addition to Dapr support, Container Apps also provides a managed Kubernetes Event Driven Autoscaling (KEDA) experience. Through the abstraction of infrastructure management and the incorporation of open source technology, Azure Container Apps provides an ideal target for the deployment of the reddog application. If you are interested in how Azure Container Apps compares to other container hosting options in Azure, visit the Azure Container Apps [documentation](https://docs.microsoft.com/en-us/azure/container-apps/compare-options)

*Please note that Azure Container Apps is currently in Public Preview and therefore is not recommended for Production workloads

### Architecture 

![Architecture diagram](assets/reddog_containerapps.png)

For insight into the various microservices and their functionality, visit the [codebase repo](https://github.com/Azure/reddog-code). For the deployment, there will be a single Container Apps Environment hosting nine respective Container Apps: 
| Service          | Ingress |  Dapr Component(s) | KEDA Scale Rule(s) |
|------------------|---------|--------------------|--------------------|
| Traefik | Internal | Dapr not-enabled | n/a |
| UI | External | Dapr not-enabled | n/a |
| Order Service | Internal | PubSub: Azure Service Bus | n/a |
| Accounting Service | Internal | PubSub: Azure Service Bus | n/a |
| Receipt Service | Internal | PubSub: Azure Service Bus, Binding: Azure Blob | Azure Service Bus Topic Length |
| Loyalty Service | Internal | PubSub: Azure Service Bus, State: Azure Cosmos DB | Azure Service Bus Topic Length |
| Makeline Service | Internal | PubSub: Azure Service Bus, State: Azure Redis | Azure Service Bus Topic Length |
| Virtual Worker | Internal | Binding: Cron | n/a |
| Virtual Customer | n/a | n/a | n/a |

*A tenth service, Bootstrapper, will also be executed. However, this service is run once to perform EF Core Migration and is subsequently scaled to 0 after completing the necessary scaffolding.


While Dapr provides flexibility around the specific component implementations leveraged for the various building blocks, this demo is opinionated. There are also a few services that make use of KEDA scale rules. The below table provides implementaion details: 

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
