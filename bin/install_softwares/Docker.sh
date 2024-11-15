#!/bin/bash

# Install Docker
install_Docker() {
    log_message "INFO" "Installing Docker in progress..."
    # Verify if Docker is already installed
    is_installed "docker" && return


    # Add Docker's official GPG key:
    sudo apt-get update > /dev/null 2>> "$LOG_FILE"
    apt_get_install ca-certificates curl 
    sudo install -m 0755 -d /etc/apt/keyrings
    verify_command "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
    # verify if the download was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Docker GPG key"
        FAILED_INSTALLATIONS+=("Docker")
        return
    fi

    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker
    verify_command "apt_get_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Docker"
        FAILED_INSTALLATIONS+=("Docker")
        return
    fi

    # Docker command to non-sudo user
    sudo groupadd docker
    sudo usermod -aG docker "$USER"
    newgrp docker

    log_message "INFO" "Docker successfully installed and added to user group"
}