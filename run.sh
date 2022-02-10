# Linux/Mac only
# export LOCATION="canadacentral" # Must be Canada Central or North Central US today
export LOCATION="eastus"

az deployment sub create -f ./deploy/bicep/main.bicep -l $LOCATION -n briar-reddog-3