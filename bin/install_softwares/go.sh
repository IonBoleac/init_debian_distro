#!/bin/bash

# Install GO from tar file
install_GO() {
    local GO_DIRECTORY="$HOME/go"
    local GO_VERSION=1.23.2
    local GO_TAR_FILE="go$GO_VERSION.linux-amd64.tar.gz"
    local GO_URL="https://go.dev/dl/$GO_TAR_FILE"

    log_message "INFO" "Installing GO in progress... Install GO version: $GO_TAR_FILE from a tar file"
    log_message "INFO" "Installing it in local directory: $GO_DIRECTORY"

    # Verify if GO already exists
    if [ -d "$GO_DIRECTORY" ]; then
        log_message "INFO" "GO directory already exists with version: $GO_VERSION."
        return
    fi

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