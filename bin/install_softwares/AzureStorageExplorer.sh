#!/bin/bash

# Function to install Azure Storage Explorer
install_AzureStorageExplorer() {
    log_message "INFO" "Installing Azure Storage Explorer in progress..."
    # Verify if Azure Storage Explorer is already installed
    is_installed "storage-explorer" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would install Azure Storage Explorer via snap"
        log_message "INFO" "[DRY-RUN] Would connect to password-manager-service interface"
        log_message "INFO" "[DRY-RUN] Would create ~/.snap-connect.sh script"
        log_message "INFO" "[DRY-RUN] Would configure autostart for snap-connect"
        log_message "INFO" "Azure Storage Explorer successfully installed"
        return
    fi

    verify_command "sudo snap install storage-explorer"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Azure Storage Explorer"
        FAILED_INSTALLATIONS+=("Azure Storage Explorer")
        return
    fi

    # Connect to password-manager-service interface
    verify_command "sudo snap connect storage-explorer:password-manager-service :password-manager-service"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to connect to password-manager-service interface"
        FAILED_INSTALLATIONS+=("Azure Storage Explorer")
        return
    fi

    # Create an executable run script
    touch ~/.snap-connect.sh

    # verify using ll comand if the file is created


    echo "#!/bin/bash
snap connect storage-explorer:password-manager-service :password-manager-service" > ~/.snap-connect.sh
    
    # Make the script executable
    chmod +x ~/.snap-connect.sh

    # Verify if the .config/autostart directory exists
    if [ ! -d ~/.config/autostart ]; then
        mkdir -p ~/.config/autostart
    fi

    # Make it run on startup
    touch ~/.config/autostart/snap-connect.sh.desktop
    echo "[Desktop Entry]
Exec=/home/$USER/.snap-connect.sh
Icon=dialog-scripts
Name=snap-connect.sh
Type=Application
X-KDE-AutostartScript=true" > ~/.config/autostart/snap-connect.sh.desktop

    log_message "INFO" "Azure Storage Explorer successfully installed"
}