#!/bin/bash

# Install Helm - Kubernetes package manager
install_helm() {
    log_message "INFO" "Installing Helm in progress..."
    # Verify if Helm is already installed
    is_installed "helm" && return

    # Download Helm installation script
    verify_command "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o get_helm.sh"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Helm installation script. Check internet connection or download manually from https://helm.sh/docs/intro/install/"
        FAILED_INSTALLATIONS+=("Helm")
        rm -f get_helm.sh
        return
    fi

    # Make script executable
    chmod +x get_helm.sh

    # Run installation script
    verify_command "./get_helm.sh"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Helm. See logs for details or try manual installation from https://helm.sh/"
        FAILED_INSTALLATIONS+=("Helm")
        rm -f get_helm.sh
        return
    fi

    # Clean up installation script
    rm -f get_helm.sh

    # Verify installation
    if command -v helm &> /dev/null; then
        helm version
        log_message "INFO" "Helm successfully installed"
    else
        log_message "ERROR" "Helm installation completed but command not found in PATH"
        FAILED_INSTALLATIONS+=("Helm")
        return
    fi
}
