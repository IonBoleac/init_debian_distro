#!/bin/bash


install_kustomize() {
    log_message "INFO" "Installing kustomize in progress..."
    # Verify if kustomize is already installed
    is_installed "kustomize" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download and execute kustomize install script from GitHub"
        log_message "INFO" "[DRY-RUN] kustomize binary would be downloaded successfully"
        log_message "INFO" "[DRY-RUN] Would install kustomize to /usr/local/bin/kustomize"
        log_message "INFO" "kustomize successfully installed"
        return
    fi

    # Download kustomize
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download kustomize. Check internet connection or try manual install from https://kubectl.docs.kubernetes.io/installation/kustomize/"
        FAILED_INSTALLATIONS+=("kustomize")
        return
    fi

    # Verify the kustomize binary
    if [ -f kustomize ]; then
        log_message "INFO" "kustomize binary downloaded successfully"
        
        # Install kustomize
        sudo install -o root -g root -m 0755 kustomize /usr/local/bin/kustomize

        # Clean up downloaded file
        rm -f kustomize

        # Verify the installation
        kustomize version

        log_message "INFO" "kustomize successfully installed"
    else
        log_message "ERROR" "Failed to download kustomize binary. Installation script did not produce expected output. Check logs for details."
        FAILED_INSTALLATIONS+=("kustomize")
        return
    fi
}