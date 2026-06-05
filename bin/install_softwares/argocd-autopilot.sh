#!/bin/bash
# Install Argo CD Autopilot CLI tool
install_argocd_autopilot() {
    log_message "INFO" "Installing Argo CD Autopilot CLI tool..."
    # Verify if argocd-autopilot is already installed
    is_installed "argocd-autopilot" && return

    local AARCH
    AARCH="$(dpkg --print-architecture)"   # amd64 / arm64

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download argocd-autopilot-linux-${AARCH}.tar.gz from official GitHub release"
        log_message "INFO" "[DRY-RUN] Would install argocd-autopilot binary to /usr/local/bin/argocd-autopilot"
        log_message "INFO" "Argo CD Autopilot CLI tool successfully installed"
        return
    fi

    local VERSION
    VERSION="$(curl -fsSL https://api.github.com/repos/argoproj-labs/argocd-autopilot/releases/latest 2>/dev/null \
               | grep -Po '"tag_name": "\K[^"]+')"
    if [ -z "$VERSION" ]; then
        log_message "ERROR" "Could not determine latest argocd-autopilot version (GitHub API). Skipping."
        FAILED_INSTALLATIONS+=("argocd-autopilot")
        return
    fi

    local BINARY="argocd-autopilot-linux-${AARCH}"
    if ! curl -fsSL --output - \
        "https://github.com/argoproj-labs/argocd-autopilot/releases/download/${VERSION}/${BINARY}.tar.gz" \
        | tar zxf - "./${BINARY}"; then
        log_message "ERROR" "Failed to download/extract argocd-autopilot ${VERSION}."
        FAILED_INSTALLATIONS+=("argocd-autopilot")
        return
    fi

    if ! sudo install -m 0755 "./${BINARY}" /usr/local/bin/argocd-autopilot; then
        log_message "ERROR" "Failed to install argocd-autopilot to /usr/local/bin"
        FAILED_INSTALLATIONS+=("argocd-autopilot")
        rm -f "./${BINARY}"
        return
    fi

    rm -f "./${BINARY}"
    log_message "INFO" "Argo CD Autopilot CLI tool ${VERSION} successfully installed"
}
