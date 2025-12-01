#!/bin/bash

install_Microk8s() {
    log_message "INFO" "Installing Microk8s in progress..."
    # Verify if Microk8s is already installed
    is_installed "microk8s" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would install Microk8s via snap"
        log_message "INFO" "[DRY-RUN] Would add user to microk8s group"
        log_message "INFO" "[DRY-RUN] Would create ~/.kube directory with restricted permissions"
        log_message "INFO" "Microk8s successfully installed. Restart your session to apply changes."
        return
    fi

    verify_command "sudo snap install microk8s --classic"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Microk8s"
        FAILED_INSTALLATIONS+=("Microk8s")
        return
    fi

    # Add to the user group
    sudo usermod -a -G microk8s $USER
    mkdir -p ~/.kube
    chmod 0700 ~/.kube

    # Verify the installation
    microk8s status --wait-ready

    log_message "INFO" "Microk8s successfully installed. Restart your session to apply changes."
}