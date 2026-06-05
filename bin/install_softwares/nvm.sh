#!/bin/bash
# script to installa nvm

# Get latest nvm version from GitHub API
get_latest_nvm_version() {
    local fallback="$1"
    
    # Try to get latest version from GitHub API
    if command -v jq &> /dev/null; then
        local version
        version=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" 2>/dev/null | \
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

install_nvm() {
    local NVM_VERSION_FALLBACK="v0.40.3"
    
    log_message "INFO" "Installing nvm in progress..."
    # nvm è una funzione di shell, non un eseguibile: controlla la directory
    if [ -d "$HOME/.nvm" ]; then
        log_message "INFO" "nvm is already installed (~/.nvm exists). Skipping."
        return
    fi

    # Get latest version (with fallback)
    local NVM_VERSION
    NVM_VERSION=$(get_latest_nvm_version "$NVM_VERSION_FALLBACK")
    
    # Log the version being installed
    if [ "$NVM_VERSION" = "$NVM_VERSION_FALLBACK" ]; then
        log_message "WARN" "Using fallback nvm version: $NVM_VERSION"
    else
        log_message "INFO" "Latest nvm version from GitHub API: $NVM_VERSION"
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download and install nvm from GitHub"
        log_message "INFO" "[DRY-RUN] Would configure nvm in shell profile"
        log_message "INFO" "NVM $NVM_VERSION successfully installed and configured. Restart your shell to use nvm"
        return
    fi

    verify_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download/install nvm. Check internet connection or install manually from https://github.com/nvm-sh/nvm"
        FAILED_INSTALLATIONS+=("nvm")
        return
    fi

    # Configure nvm nel profilo della shell corretta (idempotente)
    local RC_FILE="$HOME/.bashrc"
    [ "${USER_SHELL:-}" = "zsh" ] && RC_FILE="$HOME/.zshrc"
    if ! grep -q 'NVM_DIR="$HOME/.nvm"' "$RC_FILE" 2>/dev/null; then
        {
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm completion'
        } >> "$RC_FILE"
    fi

    # Verify installation
    if [ -d "$HOME/.nvm" ]; then
        log_message "INFO" "NVM $NVM_VERSION successfully installed and configured. Restart your shell to use nvm"
    else
        log_message "ERROR" "NVM installation failed - directory not created"
        FAILED_INSTALLATIONS+=("nvm")
        return
    fi
}