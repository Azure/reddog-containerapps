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
exit 0
az deployment group create \
    --name reddog-deploy \
    --resource-group $RG \
    --only-show-errors \
    --template-file ./deploy/main.bicep