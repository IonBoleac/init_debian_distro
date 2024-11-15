#!/bin/bash

# Install VSCode
install_VSCode() {
    log_message "INFO" "Installing VSCode in progress..."
    # Verify if VSCode is already installed
    is_installed "code" && return

    # Download and install VSCode
    verify_command "wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb"

    # verify if the download was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download VSCode"
        FAILED_INSTALLATIONS+=("VSCode")
        return
    fi

    verify_command "sudo dpkg -i vscode.deb"

    # verify if the installation was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install VSCode"
        FAILED_INSTALLATIONS+=("VSCode")
        return
    fi

    echo "VSCode installed"
    log_message "INFO" "VSCode successfully installed"
}