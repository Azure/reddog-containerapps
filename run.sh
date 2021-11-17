# Linux/Mac only
export LOCATION="canadacentral" # Must be Canada Central or North Central US today

az deployment sub create -f ./deploy/bicep/main.bicep -l $LOCATION -n ca-reddog