#!/bin/bash
# script to installa nvm

install_nvm() {
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

    verify_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
    
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
        log_message "INFO" "NVM successfully installed and configured. Restart shell or run 'source ~/.bashrc' to use nvm"
    else
        log_message "ERROR" "NVM installation failed - directory not created"
        FAILED_INSTALLATIONS+=("nvm")
        return
    fi
}