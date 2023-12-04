# *nix only
$RG="reddog"
$LOCATION="westeurope"
$SUB_ID="<YourSubscriptionID>"

# Follow Azure CLI prompts to authenticate to your subscription of choice
az login
# If you're struggling to log on, try using the command below:
# az login --tenant <YourTenantID> --use-device-code
az account set --subscription $SUB_ID

# Create resource group
az group create -n $RG -l $LOCATION

# Deploy all infrastructure and reddog apps
az deployment group create -n reddog -g $RG -f ./deploy/bicep/main.bicep

# Show outputs for bicep deployment
az deployment group show -n reddog -g $RG -o json --query properties.outputs.urls.value