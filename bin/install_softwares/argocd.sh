#!/bin/bash
# Install argocd CLI tool
install_argocd() {
    log_message "INFO" "Installing Argo CD CLI tool..."
    # Verify if argocd is already installed
    is_installed "argocd" && return
    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download argocd-linux-amd64.tar.gz from official source"
        log_message "INFO" "[DRY-RUN] Would extract and move argocd binary to /usr/local/bin/argocd"
        log_message "INFO" "Argo CD CLI tool successfully installed"
        return
    fi
    verify_command "wget https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/openshift-gitops/1.19.0-48/argocd-linux-amd64.tar.gz"
    verify_command "tar -xvzf argocd-linux-amd64.tar.gz"
    verify_command "sudo mv argocd-linux-amd64 /usr/local/bin/argocd"
    verify_command "rm -f argocd-linux-amd64.tar.gz"
}