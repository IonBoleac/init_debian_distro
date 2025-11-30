#!/bin/bash

install_kind(){
    log_message "INFO" "Installing kind in progress..."
    # Verify if kind is already installed
    is_installed "kind" && return

    # For AMD64 / x86_64
    if [ "$(uname -m)" = x86_64 ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
    # For ARM64
    elif [ "$(uname -m)" = aarch64 ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-arm64
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