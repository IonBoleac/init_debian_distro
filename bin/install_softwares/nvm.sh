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
    # Verify if nvm is already installed
    is_installed "nvm" && return
    # if is_installed "nvm"; then
    #     log_message "INFO" "nvm is already installed."
    #     read -p "Do you want to reinstall with the newest nvm? (y/n): " choice
    #     case "$choice" in
    #         y|Y ) log_message "INFO" "Reinstalling nvm...";;      
    #         n|N ) log_message "INFO" "Skipping nvm installation."; return;;
    #         * ) log_message "INFO" "Invalid choice. Skipping nvm installation."; return;;
    #     esac
    # fi

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
        log_message "INFO" "NVM $NVM_VERSION successfully installed and configured. Restart shell or run 'source ~/.bashrc' to use nvm"
        return
    fi

    verify_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download/install nvm. Check internet connection or install manually from https://github.com/nvm-sh/nvm"
        FAILED_INSTALLATIONS+=("nvm")
        return
    fi

    # Configure nvm in shell profile
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.bashrc
    
    # Verify installation
    if [ -d "$HOME/.nvm" ]; then
        log_message "INFO" "NVM $NVM_VERSION successfully installed and configured. Restart shell or run 'source ~/.bashrc' to use nvm"
    else
        log_message "ERROR" "NVM installation failed - directory not created"
        FAILED_INSTALLATIONS+=("nvm")
        return
    fi
}