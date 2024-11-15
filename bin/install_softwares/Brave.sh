#!/bin/bash

# Install Brave browser
install_Brave() {
    log_message "INFO" "Installing Brave in progress..."
    # Verify if Brave is already installed
    is_installed "brave-browser" && return

    # Download and install Brave
    verify_command "sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Brave keyring"
        FAILED_INSTALLATIONS+=("Brave")
        return
    fi
    
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt-get update
    apt_get_install brave-browser

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Brave"
        FAILED_INSTALLATIONS+=("Brave")
        return
    fi

    log_message "INFO" "Brave successfully installed"
}

