#!/bin/zsh

# Version number
VERSION="0.0.16"

# function to show the version
function show_version() {
    echo "awspmapp version $VERSION"
}


function set_aws_profile() {
    # If there is not .awspmapp folder create it and 
    if [ ! -d ~/.awspmapp ]; then
        mkdir ~/.awspmapp
    fi
    # save the selected one to a .current_profile file in the .awspmapp folder
    echo $1 > ~/.awspmapp/current_profile
    # export the selected profile to whole shells so that it can be used in other scripts
    if [ "$BASH_SOURCE" = "$0" ]; then
        export AWS_PROFILE=$1    
    fi
    
}

function list_aws_profiles() {
    # Check the AWS_PROFILE to find the current profile and highlight it and put a star next to it
    local current_profile=$AWS_PROFILE
    echo "Current Profile: $current_profile"
    echo "------------------------"

    
    grep '\[' ~/.aws/credentials | sed 's/\[\|\]//g' | while read -r profile; do
        # echo $profile
        #remove [ and ] from the profile name 
        profile_name=$(echo $profile | tr -d '[]')
        
        # echo "Current: $current_profile"
        #compare the profile name with the current profile and add a star next to profile name if they are the same
        if [ "$profile_name" = "$current_profile" ]; then
            # change color to green
            printf "\033[0;32m"
            printf "%s  *" $profile_name
            # reset color
            printf "\033[0m"
        else
            printf "%s" $profile_name
        fi
        printf "\n"

    done

    # # echo "$profiles"
    # for profile in $profiles; do
    #     # Remove [ and remove ] from the profile name
    #     profile_name=$(echo $profile | tr -d '[]')
    #     echo -e "$profile_name"
    #     echo -e "$current_profile"

    #     # if [ "$profile_name" = "$current_profile" ]; then
    #     #     echo "ooo $profile_name"
    #     # else
    #     #     echo "$profile_name"
    #     # fi
    # done
    # grep '\[' ~/.aws/credentials | sed 's/\[\|\]//g'    
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



function awspmapp() {
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
    version)
        show_version
        ;;
        # for help or with empty argument
    help | "")
        echo "-------------------------"
        echo "AWS PROFILE MANAGER"
        echo "-------------------------\n"
        echo -e "Usage: awscm {command} [profile_name]\n"
        
        echo "Commands:"
        echo -e "list:\t\t List all available AWS profiles"
        echo -e "set:\t\t Set the AWS profile to be used"
        echo -e "show:\t\t Show details of an AWS profile"  
        echo -e "delete:\t\t Delete an AWS profile"
        echo -e "version:\t\t Show the version of the tool"
        ;; 

    esac
}


# When the awspmapp script is run, check if the user has a .awspmapp folder in their home directory
# If not, create it, if it exists, check if it has a current_profile file in it
# If it does, set the AWS_PROFILE to the value in the file
# If it doesn't, set the AWS_PROFILE to the default profile
if [ -d ~/.awspmapp ]; then
    if [ -f ~/.awspmapp/current_profile ]; then
        export AWS_PROFILE=$(cat ~/.awspmapp/current_profile)
    else
        touch ~/.awspmapp/current_profile
        export AWS_PROFILE=default
    fi
else
    mkdir ~/.awspmapp
    touch ~/.awspmapp/current_profile
    echo "default" > ~/.awspmapp/current_profile
    export AWS_PROFILE=default
fi

awspmapp "$@"