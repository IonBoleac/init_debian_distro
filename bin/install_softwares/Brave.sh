#!/bin/bash

# Install Brave browser
install_Brave() {
    log_message "INFO" "Installing Brave in progress..."
    # Verify if Brave is already installed
    is_installed "brave-browser" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download Brave keyring"
        log_message "INFO" "[DRY-RUN] Would add Brave repository to /etc/apt/sources.list.d/brave-browser-release.list"
        log_message "INFO" "[DRY-RUN] Would run: sudo apt-get update"
        log_message "INFO" "[DRY-RUN] Would install package: brave-browser"
        log_message "INFO" "Brave successfully installed"
        return
    fi

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

    verify_command "apt_get_install brave-browser"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Brave. Run 'sudo apt-get update' and check if repository was added correctly."
        FAILED_INSTALLATIONS+=("Brave")
        return
    fi

    log_message "INFO" "Brave successfully installed"
}

