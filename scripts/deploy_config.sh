#!/bin/bash

# author: martin@affolter.net

# application insights: az extension add -n application-insights
# brew tap azure/functions
# brew install azure-functions-core-tools@3

env=${1:-dev}

. _config.sh

# az_login
set_subscription

stor_file="__${env}_stor.sh"
if test -f "$stor_file"; then
  echo "file exists: $stor_file"
  . $stor_file
else
  echo "file does not exist: $stor_file"
  echo "write these contents to $stor_file: export STORAGE_ACCOUNT_LIVE=\"your_storage_connectionstring_for_live_storage\""
  exit 1
fi

elastic_file="__${env}_elastic.sh"
if test -f "$elastic_file"; then
  echo "file exists: $elastic_file"
  . $elastic_file
else
  echo "file does not exist: $elastic_file"
  echo "create it using settings from elastic.io"
  exit 1
fi

cloud_id="ES_CLOUD_ID=$ES_CLOUD_ID"
user="ES_USER=$ES_USER"
pw="ES_PW=$ES_PW"
storage_account_name="STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME"
storage_account_key="STORAGE_ACCOUNT_KEY=$STORAGE_ACCOUNT_KEY"

concatenated_settings="$cloud_id $user $pw $storage_account_name $storage_account_key"

echo "appName: $appName"
echo "concatenated_settings_ $concatenated_settings"

az staticwebapp appsettings set --name $appName \
  --resource-group $resourceGroup \
  --setting-names $concatenated_settings
