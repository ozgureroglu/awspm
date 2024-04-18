#!/bin/bash


function set_aws_profile() {
    export AWS_PROFILE=$1    
}

function list_aws_profiles() {
    grep '\[' ~/.aws/credentials | sed 's/\[\|\]//g'    
}

function delete_aws_profile() {
    if [ -n "$1" ]; then
        sed -i "/\[$1\]/,/^$/d" ~/.aws/credentials
        echo "AWS profile '$1' deleted"
    else
        echo "Usage: delete_aws_profile [profile_name]"
    fi
}


function show_aws_profile_details() {
    local profile=$1
    if [ -z "$profile" ]; then
        echo "Usage: show_aws_profile_details [profile_name]"
        return
    fi

    local credentials_file=~/.aws/credentials
    local config_file=~/.aws/config
    local profile_exists=$(grep -c "\[$profile\]" $credentials_file)

    if [ "$profile_exists" -eq 0 ]; then
        echo "Profile '$profile' not found."
        return
    fi

    echo "Details for AWS profile '$profile':"
    echo "------------------------------------------"

    # Extract and display details from credentials file
    local access_key=$(grep -A 2 "\[$profile\]" $credentials_file | grep 'aws_access_key_id' | awk '{print $3}')
    local secret_key=$(grep -A 2 "\[$profile\]" $credentials_file | grep 'aws_secret_access_key' | awk '{print $3}')
    local masked_secret_key=$(echo $secret_key | sed 's/.\{5\}$/*****&/')
    
    echo "Access Key ID: $access_key"
    echo "Secret Access Key: ${secret_key:0:5}$masked_secret_key"

    # Extract and display details from config file, if it exists
    if [ -f "$config_file" ]; then
        local region=$(grep -A 2 "\[profile $profile\]" $config_file | grep 'region' | awk '{print $3}')
        local output=$(grep -A 2 "\[profile $profile\]" $config_file | grep 'output' | awk '{print $3}')
        echo "Region: $region"
        echo "Output Format: $output"
    fi
}



function awspm() {
    case "$1" in
    set)
        echo "Setting AWS Profile"
        if [ -n "$2" ]; then            
            set_aws_profile "$2"
            echo "AWS profile set to '$AWS_PROFILE'"
        else
            echo "Usage: awscm set [profile_name]"
        fi
        ;;
    list)
        echo "Available AWS Profiles:"
        echo "------------------------"
        list_aws_profiles
        ;;
    delete)
        echo "Deleting AWS Profile"
        if [ -n "$2" ]; then
            sed -i "/\[$2\]/,/^$/d" ~/.aws/credentials
            echo "AWS profile '$2' deleted"
        else
            echo "Usage: awscm delete [profile_name]"
        fi
        ;;
    show)
        show_aws_profile_details "$2"
        ;;
    help)
        echo "-------------------------"
        echo "AWS PROFILE MANAGER"
        echo "-------------------------\n"
        echo -e "Usage: awscm {set|show|list|delete} [profile_name]\n"
        
        echo -e "list:\t list all available AWS profiles"
        echo -e "set:\t set the AWS profile to be used"
        echo -e "show:\t show details of an AWS profile"
        echo -e "delete:\t delete an AWS profile"
        ;; 


    *)
        echo "-------------------------"
        echo "AWS PROFILE MANAGER"
        echo "-------------------------\n"
        echo -e "\nUsage: awscm {help|set|show|list|delete} [profile_name]"
        
        ;;
    esac
}

awspm "$@"