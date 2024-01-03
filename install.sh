#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

# Check if the OS is suitable
if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
    echo "This script can only be installed on Linux or Mac"
    exit
fi

# Check if the tool is already installed
if command -v awspm &> /dev/null
then
        echo "awspm is already installed. Please uninstall it first."
        exit
fi

# Make the main script executable
chmod +x main.sh

# Move the main script to /usr/local/bin
mv main.sh /usr/local/bin/awspm