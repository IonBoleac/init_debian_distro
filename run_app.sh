#!/bin/bash

# Load environment variables
#if [[ -f "./config/.env" ]]; then
#    source "./config/.env"
#else
#    echo "Environment file not found!"
#    exit 1
#fi

# Load constants
#if [[ -f "./config/constants.sh" ]]; then
#    source "./config/constants.sh"
#else
#    echo "Constants file not found!"
#`    exit 1
#fi

# Display menu for user to choose actions
echo "Welcome to the setup script!"
echo "1. Install Software"
echo "2. Generate README"
echo "3. Verify Constants"
echo "4. Exit"

read -p "Choose an option [1-4]: " choice

case $choice in
    1)
        # Print the help function of the install_softwares.sh script
        ./bin/install_softwares.sh -h
        read -p "Flags: " flags

        # Pass the flags to the install_softwares.sh script
        ./bin/install_softwares.sh "$flags"
        ;;
    2)
        ./bin/auto_gen_readme.sh
        ;;
    3)
        ./bin/verify_constants.sh
        ;;
    4)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid option!"
        ;;
esac
