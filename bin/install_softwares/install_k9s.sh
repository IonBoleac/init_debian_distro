#!/bin/bash
# script to installa k9s

install_k9s() {
    log_message "INFO" "Installing k9s in progress..."
    # Verify if k9s is already installed
    is_installed "k9s" && return
    # if is_installed "k9s"; then
    #     log_message "INFO" "k9s is already installed."
    #     read -p "Do you want to reinstall with the newest k9s? (y/n): " choice
    #     case "$choice" in
    #         y|Y ) log_message "INFO" "Reinstalling k9s...";;
    #         n|N ) log_message "INFO" "Skipping k9s installation."; return;;
    #         * ) log_message "INFO" "Invalid choice. Skipping k9s installation."; return;;
    #     esac
    # fi

    verify_command "wget https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb && sudo apt install -y ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb"
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install k9s. Check logs for details or download manually from https://github.com/derailed/k9s"
        FAILED_INSTALLATIONS+=("k9s")
        rm -f k9s_linux_amd64.deb
        return
    fi

    # Verify installation
    if command -v k9s &> /dev/null; then
        k9s version
        log_message "INFO" "k9s successfully installed and configured"
    else
        log_message "ERROR" "k9s installation completed but command not found in PATH"
        FAILED_INSTALLATIONS+=("k9s")
        return
    fi
}