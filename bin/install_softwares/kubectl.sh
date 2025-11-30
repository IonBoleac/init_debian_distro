#!/bin/bash


# Install kubectl
install_kubectl() {
    log_message "INFO" "Installing kubectl in progress..."
    # Verify if kubectl is already installed
    is_installed "kubectl" && return
    # if is_installed "kubectl"; then
    #     log_message "INFO" "kubectl is already installed."
    #     read -p "Do you want to reinstall with the newest kubectl? (y/n): " choice
    #     case "$choice" in
    #         y|Y ) log_message "INFO" "Reinstalling kubectl...";;
    #         n|N ) log_message "INFO" "Skipping kubectl installation."; return;;
    #         * ) log_message "INFO" "Invalid choice. Skipping kubectl installation."; return;;
    #     esac
    # fi

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

    # Clean up
    rm kubectl kubectl.sha256

    # Install krew (kubectl plugin manager)
    echo "Would you like to install krew at the latest version? [y|n]"
    while :
    do
        if [ "$AUTOMATIC_START" == "true" ]; then
            res="y"
            echo "Automatic installation started."
        else
            read -n 1 res
            echo ""  # Add newline after reading single character
        fi
        
        case $res in
            y|Y)
                (
                    set -x; cd "$(mktemp -d)" &&
                    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
                    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
                    KREW="krew-${OS}_${ARCH}" &&
                    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
                    tar zxvf "${KREW}.tar.gz" &&
                    ./"${KREW}" install krew
                )
                break
            ;;
            n|N)
                echo "Skipping krew installation."
                break
            ;;
            *)
                echo "Please type 'y' or 'n'"
            ;;
        esac
    done

}
