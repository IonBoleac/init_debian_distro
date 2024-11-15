#!/bin/bash


# Install kubectl
install_kubectl() {
    log_message "INFO" "Installing kubectl in progress..."
    # Verify if kubectl is already installed
    is_installed "kubectl" && return

    # Download kubectl
    verify_command "curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl""

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download kubectl"
        FAILED_INSTALLATIONS+=("kubectl")
        return
    fi


    # Verify the kubectl binary
    verify_command "curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256""

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download kubectl.sha256"
        FAILED_INSTALLATIONS+=("kubectl")
        return
    fi

    if echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check | grep -q "kubectl: OK"; then
        log_message "INFO" "Checksum verification passed"
        
        # Install kubectl
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

        # Verify the installation
        kubectl version --client

        # Dynamically add completion based on USER_SHELL
        if [ "$USER_SHELL" = "zsh" ]; then

            echo 'source <(kubectl completion zsh)' >> ~/.zshrc
            log_message "INFO" "Zsh kubectl completion added to ~/.zshrc"
        elif [ "$USER_SHELL" = "bash" ]; then

            echo 'source <(kubectl completion bash)' >> ~/.bashrc
            log_message "INFO" "Bash kubectl completion added to ~/.bashrc"
        fi
        # Create .kube directory
        mkdir -p ~/.kube

        log_message "INFO" "kubectl successfully installed and .kube directory created"
    else
        log_message "ERROR" "Checksum verification failed"
        FAILED_INSTALLATIONS+=("kubectl")
        return
    fi
}
