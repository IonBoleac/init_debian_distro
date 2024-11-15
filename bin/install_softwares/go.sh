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
    if find "$GO_DIRECTORY" -type d -print -quit; then
        log_message "INFO" "GO directory already exists with version: $GO_VERSION."
        return
    fi

    verify_command "wget $GO_URL"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download GO $GO_TAR_FILE tar file"
        FAILED_INSTALLATIONS+=("GO")
        return
    fi

    tar -xzf $GO_TAR_FILE
    cp -r go ~/
    rm -rf go $GO_TAR_FILE
    rm -rf go

    # Add GO to PATH in .bashrc
    echo "export GOPATH=$GO_DIRECTORY" >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc

    # reload .bashrc
    source ~/.bashrc
}