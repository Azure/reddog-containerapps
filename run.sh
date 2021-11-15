# Linux/Mac only
export LOCATION="canadacentral" # Must be Canada Central or North Central US today
export SUFFIX=$RANDOM # Generate random number for unique suffix

az deployment sub create -f ./deploy/bicep/main.bicep -l $LOCATION -n ca-reddog-$SUFFIX -p suffix=$SUFFIX