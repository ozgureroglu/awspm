#!/bin/zsh

# awspmapp.sh script has VERSION variable. Write a function to get the value and increase it by 0.0.1
function increase_version() {
    local version=$(grep "VERSION=" awspmapp.sh | cut -d '"' -f2)
    local major=$(echo $version | cut -d '.' -f1)
    local minor=$(echo $version | cut -d '.' -f2)
    local patch=$(echo $version | cut -d '.' -f3)
    patch=$((patch + 1))
    echo "$major.$minor.$patch"
    # replace the version in the file add both for mac and linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/VERSION=\"$version\"/VERSION=\"$major.$minor.$patch\"/" awspmapp.sh
    else
        sed -i "s/VERSION=\"$version\"/VERSION=\"$major.$minor.$patch\"/" awspmapp.sh
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
            echo "alias awspm='source awspmapp'" >> ~/.bashrc
            source ~/.bashrc
        fi
    elif [ "$SHELL" = "/bin/sh" ]; then
        if ! grep -q "alias awspm=" ~/.zshrc; then
            echo "adding alias to zshrc"
            echo "alias awspm='source awspmapp'" >> ~/.zshrc
            source ~/.zshrc
        fi
    else
        echo "Unsupported shell"
        echo $SHELL
    fi

}

# add a function to chmod and install the script
function install_awspmapp() {
        # Increase the version number
        increase_version
        # Make the main script executable
        chmod +x awspmapp.sh

        # Copy the main script to /usr/local/bin
        cp awspmapp.sh /usr/local/awspmapp.sh

        create_source_alias       
}


# Check if the script is run as root
if [ "$EUID" -ne 0 ]
    then echo "\nRoot privileges are required to install awspmapp. Please run with sudo."
    exit
fi

# Check if the OS is suitable
if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
    echo "This script can only be installed on Linux or Mac"
    exit
else
    echo "Installing awspmapp on $OSTYPE"
fi

# Check if the tool is already installed; if so, ask the user for permission to override it 
if command -v awspmapp &> /dev/null
then
        echo "awspmapp is already installed. Do you want to override it? (y/n)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
            then
                    echo "Removing the old version..."
                    rm /usr/local/awspmapp.sh
                    install_awspmapp
        else
                echo "Exiting..."
                exit
        fi
else
        echo "awspmapp not installed. Proceeding with the installation..."
        install_awspmapp
fi


# Check if the awspmapp exists in /usr/local/bin and it is a symlink; if so leave it, if not create a symlink
if [ -L /usr/local/bin/awspmapp ]
then
    echo "awspmapp symlink exists"
else
    ln -s /usr/local/awspmapp.sh /usr/local/bin/awspmapp
    echo "awspmapp symlink created"
fi


