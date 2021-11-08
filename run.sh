export RESOURCE_GROUP_NAME="capps-reddog" # All the resources would be deployed in this resource group
export LOCATION="canadacentral" # Must be Canada Central or North Central US today

az group create -n $RESOURCE_GROUP_NAME -l $LOCATION  

az deployment group create -g $RESOURCE_GROUP_NAME --template-file  capps-env.bicep  

az deployment group create -g $RESOURCE_GROUP_NAME --template-file  order-service.bicep    
az deployment group create -g $RESOURCE_GROUP_NAME --template-file  make-line-service.bicep    
az deployment group create -g $RESOURCE_GROUP_NAME --template-file  loyalty-service.bicep    
az deployment group create -g $RESOURCE_GROUP_NAME --template-file  receipt-generation-service.bicep    

az deployment group create -g $RESOURCE_GROUP_NAME --template-file  virtual-worker.bicep
az deployment group create -g $RESOURCE_GROUP_NAME --template-file  virtual-customer.bicep