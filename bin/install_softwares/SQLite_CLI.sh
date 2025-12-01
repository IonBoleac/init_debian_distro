#!/bin/bash

# Function to install SQLite CLI
intall_SQLite_CLI() {
    log_message "INFO" "Installing SQLite CLI in progress..."
    # Verify if SQLite is already installed
    is_installed "sqlite3" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would install sqlite3 package"
        log_message "INFO" "SQLite CLI successfully installed"
        return
    fi

    # Install SQLite
    verify_command "sudo apt-get install sqlite3 -y"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install SQLite. Run 'sudo apt-get update' and check repository access."
        FAILED_INSTALLATIONS+=("SQLite")
        return
    fi

    log_message "INFO" "SQLite CLI successfully installed"
}