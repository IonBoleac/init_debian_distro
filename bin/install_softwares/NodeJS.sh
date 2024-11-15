#!/bin/bash

# Install NodeJS
install_NodeJS() {
    log_message "INFO" "Installing Node.js in progress..."
    # Verify if Node.js is already installed
    is_installed "node" && return

    # Download and install Node.js
    verify_command "curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash -"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Node.js setup script"
        FAILED_INSTALLATIONS+=("Node.js")
        return
    fi

    verify_command "apt_get_install nodejs"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Node.js"
        FAILED_INSTALLATIONS+=("Node.js")
        return
    fi

    log_message "INFO" "Node.js successfully installed with the version $(node -v)"

    npm install -g npm@latest
    log_message "INFO" "Npm successfully updated with the version $(npm -v)"
}