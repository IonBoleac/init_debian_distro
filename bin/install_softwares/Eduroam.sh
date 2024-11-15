#!/bin/bash

# Verify if .env exists
verify_env() {
    if [ -f "./config/.env" ]; then
        source ./config/.env
        log_message "INFO" "./config/.env file exists and successfully loaded"
    else
        echo ".env file does not exist"
        log_message "ERROR" "./config/.env file does not exist"
        return 1
    fi
    # Verify if EDUROAM_USERNAME and EDUROAM_PASSWORD are set correctly
    if [ "${EDUROAM_USERNAME:-}" = "EDUROAM_USERNAME" ] || [ "${EDUROAM_PASSWORD:-}" = "EDUROAM_PASSWORD" ] || [ -z "$EDUROAM_USERNAME" ] || [ -z "$EDUROAM_PASSWORD" ]; then
        log_message "ERROR" "Please change the default EDUROAM_USERNAME and EDUROAM_PASSWORD variables in .env"
        return 1  # Use 'exit 1' if running as a script
    fi
}

# Install Eduroam
install_Eduroam() {
    script_path="scripts/eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py"
    log_message "INFO" "Installing Eduroam in progress..."

    # Verify environment
    if ! verify_env; then
        log_message "ERROR" "Environment verification failed"
        FAILED_INSTALLATIONS+=("Eduroam")
        return
    fi

    # Check if Eduroam is already configured
    if nmcli connection show | grep -q "eduroam"; then
        log_message "INFO" "Eduroam configuration already exists"
        #FAILED_INSTALLATIONS+=("Eduroam")
        return
    fi

    # Check for the Eduroam script
    if [ ! -f $script_path ]; then
        log_message "ERROR" "The Eduroam script $script_path does not exist"
        FAILED_INSTALLATIONS+=("Eduroam")
        return
    fi

    # Validate credentials
    if [[ -z "$EDUROAM_USERNAME" || -z "$EDUROAM_PASSWORD" ]]; then
        log_message "ERROR" "Eduroam username or password is not set"
        FAILED_INSTALLATIONS+=("Eduroam")
        return
    fi

    # print
    # Execute the Eduroam script
    if python3 $script_path -u "$EDUROAM_USERNAME" -p "$EDUROAM_PASSWORD"; then
        log_message "INFO" "Eduroam successfully configured"
    else
        log_message "ERROR" "Failed to execute Eduroam script."
        FAILED_INSTALLATIONS+=("Eduroam")
    fi
}