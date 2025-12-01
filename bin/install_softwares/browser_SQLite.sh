#!/bin/bash


# Function to install browser SQLite
install_browser-SQLite() {
    log_message "INFO" "Installing SQLite Browser in progress..."
    is_installed "sqlitebrowser" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would install sqlitebrowser package"
        log_message "INFO" "SQLite Browser successfully installed"
        return
    fi

    verify_command "sudo apt-get install sqlitebrowser -y"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install SQLite Browser. Run 'sudo apt-get update' and check repository access."
        FAILED_INSTALLATIONS+=("SQLite Browser")
        return
    fi
    log_message "INFO" "SQLite Browser successfully installed"
}