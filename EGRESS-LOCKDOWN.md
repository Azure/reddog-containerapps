# Egress Lockdown

## Introduction

This doc walks through a sample configuration of a locked down network infrastructure. It will create the Virtual Network, Subnets, Firewall and Route Table to force egress traffic out through the firewall. It also provides the minimum firewall rules needed by Azure Container Apps and the Red Dog application.

> **Note:** If you already have a virutal network configured for egress control through your enterprise egress firewall, you can skip to the rules section and share those with your network admin to setup access before deploying the application.

## Prepare the Vnet

First we'll setup the network infrastructure. We'll keep this in it's on Resource Group to make it easier to delete and redeploy the red dog components later.

```bash
# Set the Resource Group Name and Region Environment Variables
RG=RedDogACAEgressLockdown-Infra
LOC=eastus

# Create Resource Group
az group create -g $RG -l $LOC

# Set an environment variable for the VNet name
VNET_NAME=aca-vnet

# Create the Vnet along with the initial subnet for ACA
az network vnet create \
-g $RG \
-n $VNET_NAME \
--address-prefix 10.140.0.0/16 \
--subnet-name aca \
--subnet-prefix 10.140.0.0/27

az network vnet subnet update \
--resource-group $RG \
--vnet-name $VNET_NAME \
--name aca \
--delegations 'Microsoft.App/environments'

# Adding a subnet for the Azure Firewall
az network vnet subnet create \
--resource-group $RG \
--vnet-name $VNET_NAME \
--name AzureFirewallSubnet \
--address-prefix 10.140.1.0/24

# Get the ACA Subnet Resource ID for later use
PRIV_ACA_ENV_SUBNET_ID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME -n aca --query id -o tsv)

```

## Create the Firewall

```bash
# Create Azure Firewall Public IP
az network public-ip create -g $RG -n azfirewall-ip --sku "Standard"

# Create Azure Firewall
az extension add --name azure-firewall
FIREWALLNAME=reddog-egress
az network firewall create -g $RG -n $FIREWALLNAME --enable-dns-proxy true

# Configure Firewall IP Config
az network firewall ip-config create -g $RG -f $FIREWALLNAME -n aca-firewallconfig --public-ip-address azfirewall-ip --vnet-name $VNET_NAME
```

## Configure the Firewall Rules for ACA and Red Dog

```bash
# Create list of FQDNs for the rule
TARGET_FQDNS=('mcr.microsoft.com' \
'*.data.mcr.microsoft.com' \
'*.blob.core.windows.net' \
'packages.microsoft.com' \
'auth.docker.io' \
'registry-1.docker.io' \
'index.docker.io' \
'dseasb33srnrn.cloudfront.net' \
'production.cloudflare.docker.com' \
'archive.ubuntu.com' \
'security.ubuntu.com' \
'dl-cdn.alpinelinux.org' \
'marketplace.azurecr.io' \
'marketplaceeush.cdn.azcr.io' \
'ghcr.io' \
'pkg-containers.githubusercontent.com' \
'*.servicebus.windows.net')

# Create the application rule for ACA Container Registry Access
az network firewall application-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aca-cr' \
-n 'aca-cr' \
--source-addresses '*' \
--protocols 'http=80' 'https=443' \
--target-fqdns ${TARGET_FQDNS[@]} \
--action allow --priority 200


az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'reddogfwnr' \
-n 'svcbus' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses  "ServiceBus" \
--destination-ports 5671 443 \
--action allow --priority 400

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'reddogfwnr' \
-n 'sqltcp' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses  "Sql" \
--destination-ports 1433 11000-11999

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'reddogfwnr' \
-n 'cosmos' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses  "AzureCosmosDB" \
--destination-ports 443 6380

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'reddogfwnr' \
-n 'storage' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses  "Storage" \
--destination-ports 443

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'reddogfwnr' \
-n 'monitor' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses  "AzureMonitor" \
--destination-ports 443
```

## Set up the Route Table

```bash
# Get the public and private IP of the firewall for the routing rules
FWPUBLIC_IP=$(az network public-ip show -g $RG -n azfirewall-ip --query "ipAddress" -o tsv)
FWPRIVATE_IP=$(az network firewall show -g $RG -n $FIREWALLNAME --query "ipConfigurations[0].privateIPAddress" -o tsv)

# Create Route Table
az network route-table create \
-g $RG \
-n acadefaultroutes

# Create Default Routes
az network route-table route create \
-g $RG \
--route-table-name acadefaultroutes \
-n firewall-route \
--address-prefix 0.0.0.0/0 \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $FWPRIVATE_IP

az network route-table route create \
-g $RG \
--route-table-name acadefaultroutes \
-n internet-route \
--address-prefix $FWPUBLIC_IP/32 \
--next-hop-type Internet

# Associate Route Table to ACA Subnet
az network vnet subnet update \
-g $RG \
--vnet-name $VNET_NAME \
-n aca \
--route-table acadefaultroutes
```

## Deploy the Environment and Apps

```bash
ACARG=RedDogACAEgressLockdown-App
LOC=eastus

# Create the App Resource Group
az group create -n $ACARG -l $LOC

az deployment group create -n reddog -g $ACARG -f ./deploy/bicep/main.bicep --parameters vnetSubnetId=$PRIV_ACA_ENV_SUBNET_ID

az deployment group show -n reddog -g $ACARG -o json --query properties.outputs.urls.value
```

## Create the private zone

```bash
# Get the App FQDN
APP_ENV=$(az deployment group show -n reddog -g $ACARG -o tsv --query properties.outputs.capsenvname.value)
ENVIRONMENT_DEFAULT_DOMAIN=$(az deployment group show -n reddog -g $ACARG -o tsv --query properties.outputs.capsenvfqdn.value)

# Get the App Private IP
ENVIRONMENT_STATIC_IP=$(az containerapp env show --name $APP_ENV --resource-group ${ACARG} --query properties.staticIp --out tsv)

# Create the Private Zone
az network private-dns zone create \
--resource-group $RG \
--name $ENVIRONMENT_DEFAULT_DOMAIN

VNET_ID=$(az network vnet show -g $RG -n $VNET_NAME --query id -o tsv)

az network private-dns link vnet create \
--resource-group $RG \
--name $VNET_NAME \
--virtual-network $VNET_ID \
--zone-name $ENVIRONMENT_DEFAULT_DOMAIN -e true

az network private-dns record-set a add-record \
--resource-group $RG \
--record-set-name "*" \
--ipv4-address $ENVIRONMENT_STATIC_IP \
--zone-name $ENVIRONMENT_DEFAULT_DOMAIN

```