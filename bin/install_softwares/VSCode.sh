#!/bin/bash

# Install VSCode
install_VSCode() {
    log_message "INFO" "Installing VSCode in progress..."
    # Verify if VSCode is already installed
    is_installed "code" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download VSCode .deb package"
        log_message "INFO" "[DRY-RUN] Would install VSCode via dpkg"
        log_message "INFO" "VSCode successfully installed"
        return
    fi

    # Download and install VSCode
    verify_command "wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb"

    # verify if the download was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download VSCode. Check your internet connection or download manually from https://code.visualstudio.com/"
        FAILED_INSTALLATIONS+=("VSCode")
        rm -f vscode.deb
        return
    fi

    verify_command "sudo dpkg -i vscode.deb"

    # verify if the installation was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install VSCode. Try running 'sudo apt-get install -f' to fix dependencies, then retry."
        FAILED_INSTALLATIONS+=("VSCode")
        rm -f vscode.deb
        return
    fi

    # Clean up downloaded file
    rm -f vscode.deb

    log_message "INFO" "VSCode successfully installed"
}