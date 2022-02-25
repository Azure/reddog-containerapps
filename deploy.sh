# Linux/Mac only
export RG="reddog"
export LOCATION="eastus"

az group create -n $RG -l $LOCATION

az deployment group create -n reddog -g $RG -f ./deploy/bicep/main.bicep

az deployment group show -n reddog -g $RG -o json --query properties.outputs.urls.value