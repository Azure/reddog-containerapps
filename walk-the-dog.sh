export RG=$1
export LOCATION=$2
export SUFFIX=$3

# show all params
echo '***************************************************************'
echo 'Starting Red Dog Container Apps Deployment'
echo ''
echo 'Parameters:'
echo 'LOCATION: ' $LOCATION
echo 'RG: ' $RG
echo 'LOGFILE_NAME: ' $LOGFILE_NAME
echo '***************************************************************'
echo ''

# Check for Azure login
echo ''
echo 'Checking to ensure logged into Azure CLI'
AZURE_LOGIN=0 
# run a command against Azure to check if we are logged in already.
az group list -o table
# save the return code from above. Anything different than 0 means we need to login
AZURE_LOGIN=$?

if [[ ${AZURE_LOGIN} -ne 0 ]]; then
# not logged in. Initiate login process
    az login --use-device-code
    export AZURE_LOGIN
fi

# Create Azure Resource Group
echo ''
echo "Create Azure Resource Group"
az group create -n $RG -l $LOCATION -o table

# Bicep deployment
echo ''
echo '***************************************************************'
echo 'Starting Bicep deployment of resources'
echo '***************************************************************'

az deployment group create \
    --name reddog-deploy \
    --resource-group $RG \
    --only-show-errors \
    --template-file ./deploy/bicep/main.bicep

# Deployment outputs
echo ''
echo 'Saving bicep outputs to a file'
az deployment group show -g $RG -n reddog-deploy -o json --query properties.outputs > "./outputs/bicep-outputs-$RG.json"

export CONTAINER_APPS_DOMAIN=$(cat ./outputs/bicep-outputs-$RG.json | jq -r .defaultDomain.value)
export UI="https://reddog."$CONTAINER_APPS_DOMAIN
export PRODUCT="https://reddog."$CONTAINER_APPS_DOMAIN"/product"
export MAKELINE="https://reddog."$CONTAINER_APPS_DOMAIN"/makeline/orders/Redmond"
export ACCOUNTING_ORDERMETRICS="https://reddog."$CONTAINER_APPS_DOMAIN"/accounting/OrderMetrics?StoreId=Redmond"
export ORDER="https://reddog."$CONTAINER_APPS_DOMAIN"/order"

echo ''
echo '***************************************************************'
echo 'Demo successfully deployed'
echo ''
echo 'Details:'
echo ''
echo 'Resource Group: ' $RG
echo 'Container Apps Env Domain: ' $CONTAINER_APPS_DOMAIN
echo 'UI: ' $UI
echo 'Product: ' $PRODUCT
echo 'MakeLine orders: ' $MAKELINE
echo 'Accounting order metrics: '$ACCOUNTING_ORDERMETRICS
echo 'Order: ' $ORDER
echo ''
echo '***************************************************************' 