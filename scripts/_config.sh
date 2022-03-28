#!/bin/bash

# author: martin@affolter.net

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "DIR: $DIR"

env=${1:-prod}

. $DIR/_func.sh

tenant_id="9c0f6304-c41a-4891-8379-ed3cbfc54535"
subscription="affolter.NET MPN"
# devops settings
proj="bge-atf"
org="https://bodygee.visualstudio.com/"
lower_basename=$(echo $(tr '[:upper:]' '[:lower:]' <<< "$proj"))
basename=${lower_basename/./-}
settingsgroup="${basename}-settings"
connection_name="$proj Connection"
location="westeurope"
instance="https://login.microsoftonline.com/"
domain="affolter.net"

# function app name
appName="$basename-$env"
functionsAppName="$basename-fnc-$env"
functionsAppDir="../func"
functionsAppUrl="https://$functionsAppName.azurewebsites.net"

# rg name
resourceGroup="rg_${basename/-/_}_$env"
