#!/bin/zsh

# Version number
VERSION="0.0.24"

# function to show the version
function show_version() {
    echo "awspm version $VERSION"
}


function work_with_profile() {
    local profile_name=$1
    echo "Opening new terminal with AWS Profile: $profile_name"

    # If there is not .awspm folder create it
    if [ ! -d ~/.awspm ]; then
        echo "Creating ~/.awspm folder"
        mkdir ~/.awspm
    fi
    
    # save the selected one to a .current_profile file in the .awspm folder
    echo $profile_name > ~/.awspm/current_profile
    
    # Create a temporary script that will set up the environment
    cat > ~/.awspm/temp_profile_setup.sh << EOF
#!/bin/sh
export AWS_PROFILE=$profile_name
export PS1="AWSPM-$profile_name $ "
exec $SHELL
EOF
    
    chmod +x ~/.awspm/temp_profile_setup.sh
    
    # Open a new terminal with the profile setup
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open -a Terminal ~/.awspm/temp_profile_setup.sh
    else
        # Linux (assuming x-terminal-emulator is available)
        x-terminal-emulator -e ~/.awspm/temp_profile_setup.sh
    fi
}

function list_aws_profiles() {
    # Check the AWS_PROFILE to find the current profile and highlight it and put a star next to it
    local current_profile=$AWS_PROFILE
    echo "Current Profile: $current_profile"
    echo "------------------------"

    # Use grep to find profile names, exclude commented lines (starting with ';'), and remove brackets
    grep '^\[' ~/.aws/credentials | grep -v '^;' | sed 's/\[\|\]//g' | while read -r profile; do
        profile_name=$(echo $profile | tr -d '[]')
        
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
    work)
        if [ -n "$2" ]; then            
            work_with_profile "$2"
        else
            echo "Usage: awspm work [profile_name]"
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
            echo "Usage: awspm delete [profile_name]"
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
        echo "AWS PROFILE MANAGER (AWSPM)"
        echo "-------------------------\n"
        echo -e "Usage: awspm {command} [profile_name]\n"
        
        echo "Commands:"
        echo -e "list:\t\t List all available AWS profiles"
        echo -e "work:\t\t Open new terminal with specified AWS profile"
        echo -e "show:\t\t Show details of an AWS profile"  
        echo -e "delete:\t\t Delete an AWS profile"
        echo -e "version:\t Show the version of the tool"
        ;; 

    esac
}


# When the awspm script is run, check if the user has a .awspm folder in their home directory
# If not, create it, if it exists, check if it has a current_profile file in it
# If it does, set the AWS_PROFILE to the value in the file
# If it doesn't, set the AWS_PROFILE to the default profile
if [ -d ~/.awspm ]; then
    if [ -f ~/.awspm/current_profile ]; then
        export AWS_PROFILE=$(cat ~/.awspm/current_profile)
    else
        touch ~/.awspm/current_profile
        export AWS_PROFILE=default
    fi
else
    mkdir ~/.awspm
    touch ~/.awspm/current_profile
    echo "default" > ~/.awspm/current_profile
    export AWS_PROFILE=default
fi

awspm "$@"