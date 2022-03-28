#!/bin/bash

# author: martin@affolter.net

# application insights: az extension add -n application-insights
# brew tap azure/functions
# brew install azure-functions-core-tools@3

env=${1:-dev}

. _config.sh

# az_login
set_subscription

# create the resource group
az group create -n "$resourceGroup" -l "$location"

# to see if anything was already in there
az resource list -g $resourceGroup -o tsv

# create a storage account
storageAccountName="${basename/-/}${env}stor"
az storage account create \
  -n "$storageAccountName" \
  -l "$location" \
  -g "$resourceGroup" \
  --sku Standard_LRS

storageAccountKey=$(az storage account keys list -n $storageAccountName --query [0].value -o tsv)

echo
echo "create __stor.sh"
echo "export STORAGE_ACCOUNT_NAME=\"$storageAccountName\"" > __${env}_stor.sh
echo "export STORAGE_ACCOUNT_KEY"=\"$storageAccountKey\" >> __${env}_stor.sh
echo

# create an app insights instance
appInsightsName="$basename-$env-insights"
az monitor app-insights component create \
  --app "$appInsightsName" \
  --location "$location" \
  --kind web \
  -g "$resourceGroup" \
  --application-type web

# az functionapp config set --linux-fx-version "DOTNET|3.1" --resource-group $resourceGroup --name $functionsAppName
# az staticwebapp create --branch $branch_name \
#                        --location $location \
#                        --name $appName \
#                        --resource-group $resourceGroup \
#                        --source $static_site_repo \
#                        --sku Standard \
#                        --login-with-github
