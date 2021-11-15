export LOCATION="canadacentral" # Must be Canada Central or North Central US today

az deployment sub create -f ./main.bicep -l $LOCATION -n ca-reddog