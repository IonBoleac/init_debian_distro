#!/bin/bash

# Get latest GO version from official API
get_latest_go_version() {
    local fallback="$1"
    
    # Try to get latest version from Go API
    if command -v jq &> /dev/null; then
        local version=$(curl -s "https://go.dev/dl/?mode=json" 2>/dev/null | \
                       jq -r '.[0].version' 2>/dev/null | \
                       sed 's/^go//')
        
        if [ -n "$version" ] && [ "$version" != "null" ]; then
            log_message "INFO" "Go API: Latest stable version is $version"
            echo "$version"
            return 0
        fi
    fi
    
    # Fallback version if API fails or jq not available
    log_message "WARN" "Could not fetch latest GO version from API, using fallback: $fallback"
    echo "$fallback"
    return 1
}

# Install GO from tar file
install_GO() {
    local GO_DIRECTORY="$HOME/go"
    local GO_VERSION_FALLBACK="1.23.2"
    
    # Verify if GO already exists
    if [ -d "$GO_DIRECTORY" ]; then
        log_message "INFO" "GO directory already exists."
        return
    fi
    
    # Get latest version (with fallback)
    local GO_VERSION=$(get_latest_go_version "$GO_VERSION_FALLBACK")
    local GO_TAR_FILE="go$GO_VERSION.linux-amd64.tar.gz"
    local GO_URL="https://go.dev/dl/$GO_TAR_FILE"

    log_message "INFO" "Installing GO version: $GO_VERSION from tar file"
    log_message "INFO" "Installing it in local directory: $GO_DIRECTORY"

    verify_command "wget $GO_URL"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download GO $GO_TAR_FILE. Check internet connection or try manual download from https://go.dev/dl/"
        FAILED_INSTALLATIONS+=("GO")
        rm -f "$GO_TAR_FILE"
        return
    fi

    tar -xzf $GO_TAR_FILE
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to extract GO archive"
        FAILED_INSTALLATIONS+=("GO")
        rm -f "$GO_TAR_FILE"
        return
    fi

    cp -r go ~/
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to copy GO to home directory"
        FAILED_INSTALLATIONS+=("GO")
        rm -rf go "$GO_TAR_FILE"
        return
    fi
    
    # Clean up downloaded and extracted files
    rm -rf go "$GO_TAR_FILE"

    # Add GO to PATH in .bashrc
    echo "export GOPATH=$GO_DIRECTORY" >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc

    # Verify installation
    if [ -d "$GO_DIRECTORY" ]; then
        log_message "INFO" "GO successfully installed. Restart shell or run 'source ~/.bashrc' to use go"
    else
        log_message "ERROR" "GO installation failed - directory not created"
        FAILED_INSTALLATIONS+=("GO")
        return
    fi
}