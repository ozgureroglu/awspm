#!/bin/sh

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

# add a function to chmod and install the script
function install_awspm() {
        # Increase the version number
        increase_version
        # Make the main script executable
        chmod +x awspm.sh

        # Copy the main script to /usr/local/bin
        cp awspm.sh /usr/local/awspm.sh
       
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
    echo "Installing awspm on $OSTYPE"
fi

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
        echo "AWSPM not installed. Proceeding with the installation..."
        install_awspm
fi


# Check if the awspm exists in /usr/local/bin and it is a symlink; if so leave it, if not create a symlink
if [ -L /usr/local/bin/awspm ]
then
    echo "awspm symlink exists"
else
    ln -s /usr/local/awspm.sh /usr/local/bin/awspm
    echo "awspm symlink created"
fi


