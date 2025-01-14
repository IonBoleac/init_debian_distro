#!/bin/bash


install_kustomize() {
    log_message "INFO" "Installing kustomize in progress..."
    # Verify if kustomize is already installed
    is_installed "kustomize" && return

    # Download kustomize
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download kustomize"
        FAILED_INSTALLATIONS+=("kustomize")
        return
    fi

    # Verify the kustomize binary
    if [ -f kustomize ]; then
        log_message "INFO" "kustomize binary downloaded successfully"
        
        # Install kustomize
        sudo install -o root -g root -m 0755 kustomize /usr/local/bin/kustomize

        # Verify the installation
        kustomize version

        log_message "INFO" "kustomize successfully installed"
    else
        log_message "ERROR" "Failed to download kustomize binary"
        FAILED_INSTALLATIONS+=("kustomize")
        return
    fi
}