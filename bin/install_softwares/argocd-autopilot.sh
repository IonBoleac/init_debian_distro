#!/bin/bash
# Install Argo CD Autopilot CLI tool
install_argocd_autopilot() {
    log_message "INFO" "Installing Argo CD Autopilot CLI tool..."
    # Verify if argocd-autopilot is already installed
    is_installed "argocd-autopilot" && return   
    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download argocd-autopilot-linux-amd64.tar.gz from official source"
        log_message "INFO" "[DRY-RUN] Would extract and move argocd-autopilot binary to /usr/local/bin/argocd-autopilot"
        log_message "INFO" "Argo CD Autopilot CLI tool successfully installed"
        return
    fi
    export VERSION
    VERSION=$(curl --silent "https://api.github.com/repos/argoproj-labs/argocd-autopilot/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    verify_command "curl -L https://github.com/argoproj-labs/argocd-autopilot/releases/download/"$VERSION"/argocd-autopilot-linux-amd64.tar.gz | tar -xvzf -"
    verify_command " mv ./argocd-autopilot-* /usr/local/bin/argocd-autopilot"
}