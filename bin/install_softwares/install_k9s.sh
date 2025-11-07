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

    verify_command "wget https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb && apt install ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb"
    log_message "INFO" "k9s successfully installed and configured"
    verify_command "k9s version"
}