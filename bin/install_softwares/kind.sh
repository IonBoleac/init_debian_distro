#!/bin/bash

# Get latest kind version from GitHub API
get_latest_kind_version() {
    local fallback="$1"
    
    # Try to get latest version from GitHub API
    if command -v jq &> /dev/null; then
        local version
        version=$(curl -s "https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" 2>/dev/null | \
                 jq -r '.tag_name' 2>/dev/null)
        
        if [ -n "$version" ] && [ "$version" != "null" ]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Fallback version if API fails or jq not available
    echo "$fallback"
    return 1
}

install_kind(){
    local KIND_VERSION_FALLBACK="v0.27.0"
    
    log_message "INFO" "Installing kind in progress..."
    # Verify if kind is already installed
    is_installed "kind" && return

    # Get latest version (with fallback)
    local KIND_VERSION
    KIND_VERSION=$(get_latest_kind_version "$KIND_VERSION_FALLBACK")
    
    # Log the version being installed
    if [ "$KIND_VERSION" = "$KIND_VERSION_FALLBACK" ]; then
        log_message "WARN" "Using fallback kind version: $KIND_VERSION"
    else
        log_message "INFO" "Latest kind version from GitHub API: $KIND_VERSION"
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download kind binary for $(uname -m) architecture"
        log_message "INFO" "[DRY-RUN] Would set executable permissions on kind binary"
        log_message "INFO" "[DRY-RUN] Would move kind to /usr/local/bin/kind"
        log_message "INFO" "kind successfully installed"
        return
    fi

    # For AMD64 / x86_64
    if [ "$(uname -m)" = x86_64 ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
    # For ARM64
    elif [ "$(uname -m)" = aarch64 ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-arm64
    else
        log_message "ERROR" "Unsupported architecture: $(uname -m)"
        FAILED_INSTALLATIONS+=("kind")
        return
    fi

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download kind. Check internet connection or download manually from https://kind.sigs.k8s.io/"
        FAILED_INSTALLATIONS+=("kind")
        rm -f ./kind
        return
    fi

    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install kind. Check sudo permissions for /usr/local/bin/"
        FAILED_INSTALLATIONS+=("kind")
        rm -f ./kind
        return
    fi

    log_message "INFO" "kind successfully installed"
}