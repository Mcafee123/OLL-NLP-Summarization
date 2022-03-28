#!/bin/bash

# author: martin@affolter.net

exit_script() {
    if [ -z "$1" ]; then
        err="ERROR"
    else
        err=$1
    fi
    if [ -z $2 ]; then
        if [ -z $exitcode ]; then
            exitcode=0
        fi
        exitcode=$((exitcode + 1))
    else
        exitcode=$2
    fi
    echo $err
    echo "exiting: exitcode $exitcode"
    exit $exitcode
}

include_file() {
    include_file="$1"
    def_file="$2"
    if test -f "$include_file"; then
        echo "file exists: $include_file"
    else
        cp "$def_file" "$include_file"
        rm $def_file
        exit_script "FILE DID NOT EXIST $include_file -- A TEMPLATE WAS CREATED"
    fi

    samecontents=$(cmp --silent $def_file $include_file || echo "different")
    rm $def_file
    if [ "$samecontents" == "different" ]; then
        . $include_file
    else
        exit_script "PLEASE ADD CONTENTS TO $include_file"
    fi   
}

check_login() {
    echo "check login"
    username=$(az ad signed-in-user show --query "displayName" -o tsv)
    echo $username

    if [ -z "$username" ]; then
        echo "not logged in, do it interactively:"
        az login
    else
        echo "user already logged in $username"
    fi
}

az_login() {
    echo "login user $sp_devops_name"
    sp_devops_id=${1:-$SP_DEVOPS_ID}
    if [ -z "$sp_devops_id" ]; then
        exit_script "please provide SP ID as FIRST PARAMETER or environment variable SP_DEVOPS_ID"
    fi
    sp_devops_password=${2:-$SP_DEVOPS_PASSWORD}
    if [ -z "$sp_devops_password" ]; then
        exit_script "please provide SP PASSWORD as SECOND PARAMETER or environment variable SP_DEVOPS_PASSWORD"
    fi
    tenant_id=${3:-$tenant_id}
    if [ -z "$tenant_id" ]; then
        exit_script "please provide TENANT ID as THIRD PARAMETER or environment variable TENANT_ID"
    fi
    echo "login $sp_devops_name ($sp_devops_id) on tenant $tenant_id"
    subscriptions=$(az login --service-principal -u "$sp_devops_id" -p "$sp_devops_password" --tenant "$tenant_id" --query "[].{name:name, id:id}")
}

check_rg() {
    echo "checking resource group $rg"
    if [ "$(az group exists --name $rg)" = "false" ]; then
        echo "creating resource group $rg"...
        az group create --name $rg --location "$location"
        if [ $? -eq 0 ]; then
            echo "resource group created: $rg"
        else
            exit_script "ERROR: RESOURCE GROUP NOT CREATED"
        fi
    fi
}

openssl_rand() {
    # create password without problematic signs
    pw=`openssl rand -base64 16`
    pw=${pw/==/g}
    pw=${pw/=/g}
    pw=${pw/++/p}
    pw=${pw/+/p}
    pw=${pw//\//b}

    if [[ $pw =~ [A-Z] && $pw =~ [a-z] && $pw =~ [0-9] ]]; then
        echo "$pw"
    else
        echo "NOK"
    fi
}

create_password() {
    pw=$(openssl_rand)
    while [ "$pw" == "NOK" ]
    do
        pw=$(openssl_rand)
    done
    specialchars=('~' '!' '@' '#' '%' '^' '&' '*' '-' '+')
    A=$(echo $pw|wc -c) ## to get the count of characters
    P=$((RANDOM % $A)) ## to get a random position of where to insert the character.
    I=$((RANDOM % 10)) ## to get a random index number of chars array
    C=${specialchars[$I]}
    echo $pw | sed 's!^\(.\{'$P'\}\).!\1\'"$C"'!'  ## inserting the special character to string in defined position
}

set_subscription() {
    # set subscription
    echo "set subscription '$subscription' for tenant: $tenant_id"
    subs=$(az account list --query "[?name == '$subscription'] | [?tenantId == '$tenant_id']")
    if [ "$subs" == "[]" ]; then
        exit_script "subscription '$subscription' not found"
    fi
    subscriptionid=$( echo $subs | jq -r .[0].id)
    echo "subscriptionid: $subscriptionid"
    az account set --subscription "$subscriptionid"
    if [ $? -eq 0 ]; then
        echo "subscription set: $subscription"
    else
        exit_script "ERROR: SUBSCRIPTION NOT SET"
    fi
}

set_settingsgroup() {
  if [ -z $settingsgroup ]; then
    default="$(echo $proj | tr '[:upper:]' '[:lower:]')-settings"
    settingsgroup=${1:-$default} 
  fi
}

check_variablegroup() {
  grp=$(set_settingsgroup "$settingsgroup")
  settingsgroup=${1:-$grp}
  echo "check variable group \"$settingsgroup\""
  groupid=$(az pipelines variable-group list --org $org --project $proj --query "[?name=='$settingsgroup'].id" -o tsv)
  if [ -z $groupid ]; then
      groupid=$(az pipelines variable-group create --name $settingsgroup \
                                    --variables "settingsgroup=$settingsgroup" \
                                    --authorize "true" \
                                    --description "variables infrastructure" \
                                    --org $org \
                                    --project $proj\
                                    --query id -o tsv)

      if [ $? -eq 0 ]; then
          echo "variable group $settingsgroup CREATED, id: $groupid"
      else
          exit_script "variable group $settingsgroup NOT CREATED"
      fi
  else
      echo "variable group ALREADY EXISTS, id: $groupid"
  fi
}

create_variable() {
    variablename="$1"
    if [ -z "$variablename" ]; then
        exit_script "please provide variable NAME as FIRST parameter"
    fi     
    variablevalue="$2"
    if [ -z "$variablevalue" ]; then
        exit_script "please provide variable VALUE as SECOND parameter"
    fi
    override=${3:-"notset"}
    if [ "$override" != "notset" ] && [ "$override" != "y" ] && [ "$override" != "n" ]; then
        echo "override '$override' not valid. setting to 'false'"
        $override="false"
    fi
    echo "override: $override"
    variablesec=${4:-false}
    echo "secure: $variablesec"
    groupid=${5:-"$groupid"}
    if [ -z "$groupid" ]; then
        set_settingsgroup
        echo "get id of settingsgroup: $settingsgroup"
        groupid=$(az pipelines variable-group list --org $org --project $proj --query "[?name=='$settingsgroup'].id" -o tsv)
    fi
    echo "groupid: $groupid" 
    varexists=$(az pipelines variable-group variable list --group-id $groupid --org $org --project $proj --query "$variablename")
    if [ -z "$varexists" ]; then
        echo "variable does not exist"
        az pipelines variable-group variable create --group-id $groupid \
                                            --name "$variablename" \
                                            --org $org \
                                            --project $proj \
                                            --secret $variablesec \
                                            --value "$variablevalue"
        if [ $? -eq 0 ]; then
            echo "variable $variablename CREATED"
            if [ "$variablesec" == "false" ]; then
                echo "set $variablename to: $variablevalue"
            else
                echo "set secure $variablename to: ***"
            fi
        else
            exit_script "variable $variablename NOT CREATED"
        fi
    else
        if [ "$variablesec" == "false" ]; then
            echo "variable exists"
            varval=$( echo $varexists | jq -r .value )
            if [ "$variablevalue" != "$varval" ]; then
                if [ "$override" == "notset" ]; then
                    read -p "do you wish to overwrite '$varval' with '$variablevalue' (y/N)? " yn
                    if [ -z $yn ]; then
                        yn="n"
                    fi
                    echo "answer: $yn"
                else
                    yn="$override"
                fi
            fi
        else
            yn="$override"
        fi

        if [ "$yn" == "y" ] && [ "$variablevalue" != "$varval" ]; then
            az pipelines variable-group variable update --group-id $groupid \
                                            --name "$variablename" \
                                            --org $org \
                                            --project $proj \
                                            --secret $variablesec \
                                            --value "$variablevalue"

            if [ $? -eq 0 ]; then
                echo "variable $variablename UPDATED"
                if [ "$variablesec" == "false" ]; then
                    echo "set $variablename to: $variablevalue"
                else
                    echo "set secure $variablename to: ***"
                fi
            else
                exit_script "variable $variablename UPDATE ERROR"
            fi
        else
            if [ "$variablesec" == "false" ]; then
                echo "variable '$variablename' stays the same: '$varval'"
                echo "keep $variablename with: $varval"
            else
                echo "existing secure variable '$variablename' was not overwritten. delete it if you want to set a new value."
                echo "ENVIRONMENT VARIABLE NOT SET"
            fi
        fi
    fi
}

get_serviceprincipal() {
    service_principal=$(az ad sp list --all --query "[?appDisplayName == '$sp_devops_name']")
    echo "$service_principal"
}

create_serviceprincipal() {
    echo "check service principal"
    adRole=${1:-"Contributor"}
    if [ -z $adRole ]; then
        exit_script "please add AD-ROLE AS FIRST PARAMETER"
    fi
    sp_name=${2:-$sp_devops_name}
    if [ -z $sp_name ]; then
        exit_script "please add SERVICE-PRINCIPAL NAME AS SECOND PARAMETER"
    fi
    service_principal=$(get_serviceprincipal)
    if [ "$service_principal" == "[]" ]; then
        # create service principal
        echo "create service principal: $sp_name"
        service_principal=$(az ad sp create-for-rbac --name http://$sp_name  --role $adRole)
        client_secret=$( echo $service_principal | jq -r .password )
        service_principal=$(get_serviceprincipal)
    else
        echo "service principal '$sp_name' already exists, reset password"
        client_secret=$(create_password)
        az ad sp credential reset --name "$sp_name" --password "$client_secret"
    fi

    appId=$( echo $service_principal | jq -r .[0].appId )
    echo "app id: $appId"
    objectId=$( echo $service_principal | jq -r .[0].objectId )
    echo "object id: $objectId"
    tenant_id=$( echo $service_principal | jq -r .[0].appOwnerTenantId )
    echo "tenant id: $tenant_id"
    displayName=$( echo $service_principal | jq -r .[0].displayName )
    displayName="http://$displayName"
    echo "display name: $displayName"

    export SP_DEVOPS_ID="$appId"
    export SP_DEVOPS_PASSWORD="$client_secret"

    echo
    echo "create __env.sh"
    echo "export SP_DEVOPS_ID=\"$appId\"" > __${env}_env.sh
    echo "export SP_DEVOPS_PASSWORD"=\"$client_secret\" >> __${env}_env.sh
    echo
}

create_service_connection() {
  connection_name="${1:-$connection_name}"
  if [ -z $connection_name ]; then
    connection_name="$subscription-Connection"
  fi
  echo "check devops service connection"
  svcconnarr=$(az devops service-endpoint list \
      --org "$org" \
      --project "$proj" \
      --query "[?name == '$connection_name']|[?authorization.parameters.serviceprincipalid == '$appId'].id")

  if [ "$svcconnarr" != "[]" ]; then
      svcconn=$( echo $svcconnarr | jq -r .[0] )
      echo "service connection '$connection_name' (id: $svcconn) already exists"

      az devops service-endpoint delete \
          --org "$org" \
          --project "$proj" \
          --id "$svcconn" \
          --yes
      echo "service connection '$connection_name' (id: $svcconn) deleted"
  fi

  echo "create service connection '$connection_name':"
  echo "- devops-name: $appId"
  echo "- devops-password: ***"
  echo "- tenant: $tenant_id"
  echo "- subscription: $subscription ($subscriptionid)"

  export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="$client_secret"

  id=$(az devops service-endpoint azurerm create \
      --org "$org" \
      --project "$proj" \
      --azure-rm-service-principal-id "$appId" \
      --azure-rm-subscription-id "$subscriptionid" \
      --azure-rm-subscription-name "$subscription" \
      --azure-rm-tenant-id "$tenant_id" \
      --name "$connection_name" \
      --query "id" \
      -o tsv)
  echo "id: $id"

  create_variable "AZURE_SERVICE_CONNECTION" "$connection_name" "y"
  
  az devops service-endpoint update --id "$id" \
    --enable-for-all true \
    --org "$org" \
    --project "$proj"
                        
#   echo
#   echo "DON'T FORGET TO ENABLE SERVICE CONNECTION FOR ALL PIPELINES!"
#   echo
}

create_ad_app() {
    adappname=$1
    if [ -z $adappname ]; then
        exit_script "please provide a name for the ad app"
    fi
    signinpath=${2:-"/signin-oidc"}
    app=$(az ad app list --query "[?displayName == '$adappname']")
    # echo $app
    if [ "$app" == "[]" ]; then
        echo "create app: $adappname"
        app=$(az ad app create \
            --display-name "$adappname" \
            --oauth2-allow-implicit-flow false \
            --available-to-other-tenants false)
        appId=$( echo $app | jq -r .appId )
        echo "'$adappname' created: $appId"
    else
        appId=$( echo $app | jq -r .[0].appId )
        echo "$adappname already exists: $appId"
    fi

    echo "$appreg_1:"
    echo "\"Instance\": \"$instance\","
    echo "\"Domain\": \"$domain\","
    echo "\"TenantId\": $tenant_id,"
    echo "\"ClientId\": $appId,"

    echo
    appregfile="__${env}_appreg.sh"
    echo "create $appregfile"
    echo "export AzureAd__ClientId=\"$appId\"" > $appregfile
    echo "export AzureAd__Instance"=\"$instance\" >> $appregfile
    echo "export AzureAd__Domain"=\"$domain\" >> $appregfile
    echo "export AzureAd__TenantId"=\"$tenant_id\" >> $appregfile
    echo "export AzureAd__CallbackPath"=\"$signinpath\" >> $appregfile
    echo "export AzureAd__Authority"=\"$instance/$tenant_id/v2.0\" >> $appregfile
    echo
}

add_reply_url() {
    replyUrlAppId="$1"
    if [ -z $replyUrlAppId ]; then
        exit_script "please provide an appId as first parameter"
    fi
    replyUrl="$2"
    if [ -z $replyUrl ]; then
        exit_script "please provide a replyUrl as second parameter"
    fi

    existing=$(az ad app show --id $replyUrlAppId --query "replyUrls")
    existing="${existing/[/}" # remove starting bracket to make grep work
    if grep -q "$replyUrl" <<< "$existing"; then
        echo "replyUrl already exists: $replyUrl"
    else
        az ad app update --id $replyUrlAppId --add replyUrls "$replyUrl"
        echo "replyUrl added: $replyUrl"
    fi
}

