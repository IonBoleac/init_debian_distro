#!/bin/bash
# Install argocd CLI tool
install_argocd() {
    log_message "INFO" "Installing Argo CD CLI tool..."
    # Verify if argocd is already installed
    is_installed "argocd" && return

    local AARCH
    AARCH="$(dpkg --print-architecture)"   # amd64 / arm64

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download argocd-linux-${AARCH} from official GitHub release"
        log_message "INFO" "[DRY-RUN] Would install argocd binary to /usr/local/bin/argocd"
        log_message "INFO" "Argo CD CLI tool successfully installed"
        return
    fi

    local VERSION
    VERSION="$(curl -fsSL https://api.github.com/repos/argoproj/argo-cd/releases/latest 2>/dev/null \
               | grep -Po '"tag_name": "\K[^"]+')"
    if [ -z "$VERSION" ]; then
        log_message "ERROR" "Could not determine latest argocd version (GitHub API). Skipping."
        FAILED_INSTALLATIONS+=("argocd")
        return
    fi

    if ! sudo curl -fsSL -o /usr/local/bin/argocd \
        "https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-${AARCH}"; then
        log_message "ERROR" "Failed to download argocd ${VERSION}. Check internet connection."
        FAILED_INSTALLATIONS+=("argocd")
        return
    fi

    sudo chmod +x /usr/local/bin/argocd
    log_message "INFO" "Argo CD CLI tool ${VERSION} successfully installed"
}
