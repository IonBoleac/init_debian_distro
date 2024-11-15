#!/bin/bash


# Function to install browser SQLite
install_browser-SQLite() {
    log_message "INFO" "Installing SQLite Browser in progress..."
    is_installed "sqlitebrowser" && return

    verify_command "sudo apt-get install sqlitebrowser -y"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install SQLite Browser"
        FAILED_INSTALLATIONS+=("SQLite Browser")
        return
    fi
    log_message "INFO" "SQLite Browser successfully installed"
}