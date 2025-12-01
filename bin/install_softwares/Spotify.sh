#!/bin/bash

# Install Spotify
install_Spotify() {
    log_message "INFO" "Installing Spotify in progress..."
    # Verify if Spotify is already installed
    is_installed "spotify" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download Spotify repository signing keys"
        log_message "INFO" "[DRY-RUN] Would add Spotify repository to /etc/apt/sources.list.d/spotify.list"
        log_message "INFO" "[DRY-RUN] Would run: sudo apt-get update"
        log_message "INFO" "[DRY-RUN] Would install spotify-client"
        log_message "INFO" "Spotify successfully installed"
        return
    fi

    # Add the Spotify repository signing keys to be able to verify downloaded packages
    verify_command "curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Spotify repository signing keys. Check internet connection and gpg installation."
        FAILED_INSTALLATIONS+=("Spotify")
        return
    fi

    # Add the Spotify repository
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt-get update

    # Install Spotify
    verify_command "sudo apt-get install spotify-client -y"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Spotify. Run 'sudo apt-get update' and verify repository was added correctly."
        FAILED_INSTALLATIONS+=("Spotify")
        return
    fi
    log_message "INFO" "Spotify successfully installed"
}
