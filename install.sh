#!/bin/zsh

# awspm.sh script has VERSION variable. Write a function to get the value and increase it by 0.0.1
function increase_version() {
    local version=$(grep "VERSION=" awspm.sh | cut -d '"' -f2)
    local major=$(echo $version | cut -d '.' -f1)
    local minor=$(echo $version | cut -d '.' -f2)
    local patch=$(echo $version | cut -d '.' -f3)
    patch=$((patch + 1))
    echo "$major.$minor.$patch"
    # replace the version in the file add both for mac and linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/VERSION=\"$version\"/VERSION=\"$major.$minor.$patch\"/" awspm.sh
    else
        sed -i "s/VERSION=\"$version\"/VERSION=\"$major.$minor.$patch\"/" awspm.sh
    fi
    
}

function create_source_alias() {
    # Find the shell that the user is using and depending on the shell, 
    # create an alias for the awspm function to run it using source command,
    # ie. add an alias to the .bashrc or .zshrc file in the user's home directory
    # Of course if there is already an alias, don't add it again
    if [ "$SHELL" = "/bin/bash" ]; then
        if ! grep -q "alias awspm=" ~/.bashrc; then
            echo "adding alias to bashrc"
            echo "alias awspm='source awspm'" >> ~/.bashrc
            source ~/.bashrc
        fi
    elif [ "$SHELL" = "/bin/sh" ]; then
        if ! grep -q "alias awspm=" ~/.zshrc; then
            echo "adding alias to zshrc"
            echo "alias awspm='source awspm'" >> ~/.zshrc
            source ~/.zshrc
        fi
    else
        echo "Unsupported shell"
        echo $SHELL
    fi

}

# add a function to chmod and install the script
function install_awspm() {
        # Increase the version number
        increase_version
        # Make the main script executable
        chmod +x awspm.sh

        # Copy the main script to /usr/local/bin
        cp awspm.sh /usr/local/awspm.sh
        # create_source_alias       
}


# Check if the script is run as root
if [ "$EUID" -ne 0 ]
    then echo "\nRoot privileges are required to install awspm. Please run with sudo."
    exit
fi

# Check if the OS is suitable
if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
    echo "This script can only be installed on Linux or Mac"
    exit
else
    echo "System check passed: $OSTYPE\n"
fi

# If no options are provided, install the tool  
if [ $# -eq 0 ]; then
    # Check if the tool is already installed; if so, ask the user for permission to override it 
    if command -v awspm &> /dev/null
    then
            echo "awspm is already installed. Do you want to override it? (y/n)"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
                then
                        echo "Removing the old version..."
                        rm /usr/local/awspm.sh
                        install_awspm
            else
                    echo "Exiting..."
                    exit
            fi
    else
            echo "Proceeding with the installation..."
            install_awspm
    fi
fi




# Uninstall function
uninstall_awspm() {
    echo "Uninstalling awspm..."
    rm /usr/local/awspm.sh
    rm /usr/local/bin/awspm
    echo "awspm uninstalled successfully."
}

# Handle command line options
handle_options() {
    case "$1" in
        --uninstall)
            uninstall_awspm
            exit
            ;;
        --version)
            # Get current version from awspm.sh
            version=$(grep "VERSION=" awspm.sh | cut -d '"' -f2)
            echo "awspm version $version"
            exit
            ;;
        --help)
            echo "Usage: install.sh [OPTIONS]"
            echo "Options:"
            echo "  --uninstall    Uninstall awspm"
            echo "  --version      Display current version"
            echo "  --help         Display this help message"
            exit
            ;;
    esac
}

# Check if any options were provided
if [ $# -gt 0 ]; then
    handle_options "$1"
fi
