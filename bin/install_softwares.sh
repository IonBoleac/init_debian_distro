#!/bin/bash

# Load constants from the constants.sh file
source ./config/constants.sh
source ./config/log_config.sh

# Declare an array that store all the eventual failed installations
declare -a FAILED_INSTALLATIONS

# ========= Utilities functions =========

# Funtion to verify if the command are gone or not
verify_command() {
    eval "$@" > /dev/null 2>> "$LOG_FILE"
    local status=$?

    if [ $status -ne 0 ]; then
        log_message "ERROR" "Command $* failed with status $status"
        return 1
    fi
}

# Function to install packages using apt-get
apt_get_install() {
    sudo apt-get install -y "$1" > /dev/null 2>> "$LOG_FILE"
    #log_message "INFO" "$1 successfully installed"
}

# init script function needed to run the script
init_script() {
    log_message "INFO" "Initializing script"
    # Verify if wget and curl are installed
    for cmd in $COMMANDS; do
        if ! command -v "$cmd" &> /dev/null; then
            log_message "ERROR" "$cmd is required but not installed. Installing it....."
            apt_get_install "$cmd"
            log_message "INFO" "$cmd successfully installed"
        fi
    done

    # Verify the user shell
    if [[ "$SHELL" == */zsh ]]; then
        USER_SHELL="zsh"
        log_message "INFO" "Zsh shell detected"
    elif [[ "$SHELL" == */bash ]]; then
        USER_SHELL="bash"
        log_message "INFO" "Bash shell detected"
    else
        log_message "ERROR" "Unknown shell: $SHELL"
    fi


    # Verify wich type of OS is running
    if [ -f "/etc/os-release" ]; then
        source /etc/os-release
        if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
            log_message "INFO" "Debian based distribution detected"
        else
            log_message "ERROR" "This script is only for Debian based distributions"
            exit 1
        fi
    else
        log_message "ERROR" "This script is only for Devian based distributions"
        exit 1
    fi
}

# Update and upgrade
apt_update() {
    log_message "INFO" "Updating system in progress..."
    sudo apt-get update > /dev/null 2>> "$LOG_FILE"
    #sudo apt-get upgrade -y >> /dev/null 2>> "$LOG_FILE"
    #sudo apt-get autoclean >> /dev/null 2>> "$LOG_FILE"
    #sudo apt-get autoremove -y >> /dev/null 2>> "$LOG_FILE"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "System update and upgrade failed"
        return 1
    fi

    log_message "INFO" "System successfully updated and upgraded"
}

# Restart user session
restart_session() {
    su - "$USER"
    log_message "INFO" "Session restarted"
}


# Check if a software package is installed
is_installed() {
    local cmd=$1

    # Check if the command exists in the system's PATH
    if command -v "$cmd" &> /dev/null; then
        log_message "INFO" "$cmd is already installed"
        return 0
    fi

    # Check if the package is installed via APT
    if dpkg -l | grep -qw "$cmd"; then
        log_message "INFO" "$cmd is already installed via APT"
        return 0
    fi

    # Check if the package is installed via Snap
    if snap list | grep -qw "$cmd"; then
        log_message "INFO" "$cmd is already installed via Snap"
        return 0
    fi

    # If none of the checks succeeded, the package is not installed
    return 1
}

# ========= Software installation functions =========
for file in ./bin/install_softwares/*; do
    source "$file"
done


# Show help message
show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "This script installs various software tools interactively or all at once. It can also exclude specific software."
    echo "The script is designed for Debian-based distributions."
    echo
    echo "Options:"
    
    # Display grouped flags with descriptions, aligned in columns
    for action in "${!FLAG_GROUPS[@]}"; do
        case "$action" in
            "all")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${FLAG_GROUPS[$action]}" "# Install all software tools without prompts"
                ;;
            "all-excluding")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${FLAG_GROUPS[$action]} [software...]" "# Install all except specified software"
                ;;
            "install")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${FLAG_GROUPS[$action]} [software...]" "# Specify software to install (use one or more names)"
                ;;
            "help")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${FLAG_GROUPS[$action]}" "# Show this help message"
                ;;
        esac
    done

    echo
    echo "Software options for --${FLAGS_DECLARATION["-i"]} and --${FLAGS_DECLARATION["-ax"]}:"
    # Display each software, its description, and link
    for software in "${!INSTALL_FUNCTIONS[@]}"; do
        local description="${DESCRIPTION_SOFTWARE_LIST[$software]}"
        local link="${LINK_SOFTWARE_LIST[$software]}"
        printf "  %-*s %s %s\n" "$COLUMN_WIDTH" "${software}" "# $description" "${link}"
    done
    echo
    echo "Example usage:"
    printf "  %-*s %s\n" "$COLUMN_WIDTH" "$0 -ax Brave Docker" "# Install all except Brave and Docker"
    printf "  %-*s %s\n" "$COLUMN_WIDTH" "$0 -i Brave Docker" "# Install only Brave and Docker"
}

# Progress bar function based on software installation count, outputs to stderr
show_progress_bar() {
    local current=$1
    local total=$2
    local bar_length=40
    local percent=$(( (current * 100) / total ))
    local filled_length=$(( (percent * bar_length) / 100 ))

    # Create the progress bar
    local bar=$(printf "%0.s#" $(seq 1 $filled_length))
    local spaces=$(printf "%0.s " $(seq 1 $(( bar_length - filled_length ))))

    # Move the cursor to the beginning of the line and overwrite it
    printf "\r\033[KProgress: [%s%s] %d%%" "$bar" "$spaces" "$percent" >&2 # \033[K -> clears the line
}

install_one_function() {
    local software=$1
    ${INSTALL_FUNCTIONS[$software]} & #>> "$LOG_FILE" 2>&1  # Redirect software logs
            # Get the PID of the installation process
            local pid=$!

            # Monitor the progress while the installation is happening
            while kill -0 "$pid" 2>/dev/null; do
                show_progress_bar "$installed_count" "$total_packages"
                sleep 0.005  # Update the progress bar every 0.5 seconds
            done
            
            installed_count=$((installed_count + 1))
            show_progress_bar "$installed_count" "$total_packages"

            sleep 0.5
}

# verify if the required softwares are installed
verify_installation() {
    if [ ${#FAILED_INSTALLATIONS[@]} -eq 0 ]; then
        log_message "INFO" "All installations succeeded"
    else
        log_message "ERROR" "The following installations failed: ${FAILED_INSTALLATIONS[*]}"
        exit 1
    fi
}

# Install softwares based on user input
install_functions() {
    apt_update

    if [[ "$1" == "all" ]]; then
        log_message "INFO" "Installing all software tools in progress..."
        local total_packages=${#INSTALL_FUNCTIONS[@]}
        local installed_count=0
        for software in "${!INSTALL_FUNCTIONS[@]}"; do
            ${INSTALL_FUNCTIONS[$software]}  # Original line
            #install_one_function "$software" >> "$LOG_FILE" 2>&1 # This line is for progress bar but doesn't print the logs on the terminal, instead it prints on the log file
        done
        echo "" 
        log_message "INFO" "Installation completed: 100%"
        return
    elif [[ "$1" == "all-excluding" ]]; then
        shift
        local exclude=("$@")
        for software in "${!INSTALL_FUNCTIONS[@]}"; do
            if [[ ! " ${exclude[*]} " =~ ${software} ]]; then
                ${INSTALL_FUNCTIONS[$software]}
            else
                log_message "INFO" "Skipping $software as per exclusion list"
            fi
        done
        return
    fi

    # Install software based on user input (flag: --input) or all if no input
    if [ $# -gt 0 ]; then
        for software in "$@"; do
            if [[ -n "${INSTALL_FUNCTIONS[$software]}" ]]; then
                ${INSTALL_FUNCTIONS[$software]}
            else
                log_message "ERROR" "Unknown software: $software"
            fi
        done
    else
        for software in "${!INSTALL_FUNCTIONS[@]}"; do
            read -p "Install $software? [Y/n]: " input
            if [[ "$input" =~ ^[Yy]$ ]]; then
                log_message "INFO" "Installing $software in progress..."
                ${INSTALL_FUNCTIONS[$software]}
            fi
        done
    fi
}


main() {
    local selected_software=()
    local excluded_software=()
    local flag_type=""

    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "${FLAGS_DECLARATION[$1]}" in
            "all" )
                flag_type="all"
                shift
                ;;
            "all-excluding" )
                flag_type="all-excluding"
                shift
                while [[ $# -gt 0 && "$1" != "--"* ]]; do
                    excluded_software+=("$1")
                    shift
                done
                ;;
            "install" )
                flag_type="install"
                shift
                while [[ $# -gt 0 && "$1" != "--"* ]]; do
                    selected_software+=("$1")
                    shift
                done
                ;;
            "help" )
                show_help
                exit 0
                ;;
            * )
                echo "Invalid option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Run installation based on flags
    init_script
    case "$flag_type" in
        "all" )
            log_message "INFO" "Installing all software tools without prompts"
            install_functions "all"
            ;;
        "all-excluding" )
            log_message "INFO" "Installing all software tools except ${excluded_software[*]}"
            install_functions "all-excluding" "${excluded_software[@]}"
            ;;
        "install" )
            log_message "INFO" "Installing specified software ${selected_software[*]} "
            install_functions "${selected_software[@]}"
            ;;
        "" )
            log_message "INFO" "No flags provided, starting interactive installation"
            install_functions
            ;;
    esac

    # Restart user session after installation to apply changes
    log_message "INFO" "Recommend to restart user session to apply changes"
    verify_installation
    # restart_session
    
}

main "$@"