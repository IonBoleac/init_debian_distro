#!/bin/bash

# Constants
LOG_FILE="logs.log"

# Log system messages
log_message() {
    local SEVERITY=$1
    local MESSAGE=$2
    case $SEVERITY in
        "INFO") COLOR="\033[1;32m" ;;   # Green for INFO
        "ERROR") COLOR="\033[1;31m" ;;  # Red for ERROR
        *) COLOR="\033[0m" ;;           # Default terminal color
    esac
    echo -e "$(date '+%Y-%m-%d %H:%M:%S'): $COLOR$SEVERITY - $MESSAGE\033[0m" 
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $SEVERITY - $MESSAGE" >> "$LOG_FILE"
}


# Declare SOFTWARE_DETAILS and populate it with software details
# New software can be added in the following format to install it. It's must be declared in the following format
# format: ["name of the software"]="install_function;install_method;description;link"
# [""]=";;;"
declare -A SOFTWARE_DETAILS=(
    ["VSCode"]="install_VSCode;apt;Popular code editor for developers.;https://code.visualstudio.com/"
    ["Brave"]="install_Brave;apt;Privacy-focused web browser.;https://brave.com/"
    ["Docker"]="install_Docker;apt;Platform for building, sharing, and running applications with containers.;https://www.docker.com/"
    ["Eduroam"]="install_Eduroam;script;Secure, worldwide roaming access service developed for the international research and education community.;https://eduroam.org/"
    ["kubectl"]="install_kubectl;curl;command-line tool for controlling Kubernetes clusters.;https://kubernetes.io/docs/reference/kubectl/"
    ["Node.js"]="install_NodeJS;curl;JavaScript runtime built on Chrome's V8 JavaScript engine.;https://nodejs.org/en/"
    ["Spotify"]="install_Spotify;apt;Digital music streaming service.;https://open.spotify.com/intl-it"
    ["SQLite CLI"]="intall_SQLite_CLI;apt;command-line interface for SQLite.;https://sqlite.org/cli.html"
    ["SQLite Browser"]="install_browser-SQLite;apt;Visual tool to create, design, and edit database files compatible with SQLite.;https://sqlitebrowser.org/dl/"
    ["AzureStorageExplorer"]="install_AzureStorageExplorer;snap;Standalone app that makes it easy to work with Azure Storage data on Windows, macOS, and Linux.;https://azure.microsoft.com/en-us/products/storage/storage-explorer" 
    ["Microk8s"]="install_Microk8s;snap;Lightweight Kubernetes for workstations and appliances.;https://microk8s.io/"
)

# Function to extract the install function for a given software
get_install_function() {
    local software=$1
    echo "${SOFTWARE_DETAILS[$software]}" | cut -d';' -f1
}

# Function to extract the install method for a given software
get_install_method() {
    local software=$1
    echo "${SOFTWARE_DETAILS[$software]}" | cut -d';' -f2
}

# Function to extract the description for a given software
get_software_description() {
    local software=$1
    echo "${SOFTWARE_DETAILS[$software]}" | cut -d';' -f3
}

# Function to extract the install method for a given software
get_software_link() {
    local software=$1
    echo "${SOFTWARE_DETAILS[$software]}" | cut -d';' -f4
}

# Declare INSTALL_FUNCTIONS and populate it from SOFTWARE_DETAILS
declare -A INSTALL_FUNCTIONS
for software in "${!SOFTWARE_DETAILS[@]}"; do
    INSTALL_FUNCTIONS["$software"]="$(get_install_function "$software")"
done

# Declare METHOD_SOFTWARE_LIST and populate it with software install methods
declare -A METHOD_SOFTWARE_LIST
for software in "${!SOFTWARE_DETAILS[@]}"; do
    METHOD_SOFTWARE_LIST["$software"]="$(get_install_method "$software")"
done

declare -A DESCRIPTION_SOFTWARE_LIST
for software in "${!SOFTWARE_DETAILS[@]}"; do
    DESCRIPTION_SOFTWARE_LIST["$software"]="$(get_software_description "$software")"
done

# Declare LINK_SOFTWARE_LIST and populate it with software download links
declare -A LINK_SOFTWARE_LIST
for software in "${!SOFTWARE_DETAILS[@]}"; do
    LINK_SOFTWARE_LIST["$software"]="$(get_software_link "$software")"
done


# Flag mappings for parsing
declare -A FLAGS_DECLARATION=(
    ["--all"]="all"
    ["-a"]="all"
    ["--all-excluding"]="all-excluding"
    ["-ax"]="all-excluding"
    ["--install"]="install"
    ["-i"]="install"
    ["--help"]="help"
    ["-h"]="help"
)

# commands needed to run the script like wget, curl save in a variable
COMMANDS="wget curl git"

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
        if [ "$ID_LIKE" = "debian" ]; then
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
update_upgrade() {
    log_message "INFO" "Updating and upgrading system in progress..."
    sudo apt-get update > /dev/null 2>> "$LOG_FILE"
    sudo apt-get upgrade -y >> /dev/null 2>> "$LOG_FILE"
    log_message "INFO" "System successfully updated and upgraded"
}

# Verify if .env exists
verify_env() {
    if [ -f ".env" ]; then
        source .env
        log_message "INFO" ".env file exists and successfully loaded"
    else
        echo ".env file does not exist"
        log_message "ERROR" ".env file does not exist"
        return 1
    fi
    # Verify if EDUROAM_USERNAME and EDUROAM_PASSWORD are set correctly
    if [ "${EDUROAM_USERNAME:-}" = "EDUROAM_USERNAME" ] || [ "${EDUROAM_PASSWORD:-}" = "EDUROAM_PASSWORD" ] || [ -z "$EDUROAM_USERNAME" ] || [ -z "$EDUROAM_PASSWORD" ]; then
        log_message "ERROR" "Please change the default EDUROAM_USERNAME and EDUROAM_PASSWORD variables in .env"
        return 1  # Use 'exit 1' if running as a script
    fi
}

# Restart user session
restart_session() {
    su - "$USER"
    log_message "INFO" "Session restarted"
}

# Check if software is already installed
apt_is_installed() {
    local cmd=$1 > /dev/null
    if [ -x "$(command -v $cmd)" ]; then
        log_message "INFO" "$cmd is already installed"
        return 0
    else
        return 1
    fi
}

snap_is_installed() {
    local cmd=$1
    snap list | grep $cmd > /dev/null
    if [ $? -eq 0 ]; then
        log_message "INFO" "$cmd is already installed"
        return 0
    else
        return 1
    fi
}

# Install VSCode
install_VSCode() {
    # Verify if VSCode is already installed
    apt_is_installed "code" && return

    # Download and install VSCode
    wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb
    sudo dpkg -i vscode.deb

    echo "VSCode installed"
    log_message "INFO" "VSCode successfully installed"
}

install_Brave() {
    # Verify if Brave is already installed
    if [ -x "$(command -v brave-browser)" ]; then
        log_message "INFO" "Brave is already installed"
        return
    fi

    # Download and install Brave
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install brave-browser

    log_message "INFO" "Brave successfully installed"
}

install_Docker() {
    # Verify if Docker is already installed
    apt_is_installed "docker" && return


    # Add Docker's official GPG key:
    sudo apt-get update > /dev/null 2>> "$LOG_FILE"
    apt_get_install ca-certificates curl 
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker
    apt_get_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Docker command to non-sudo user
    sudo groupadd docker
    sudo usermod -aG docker "$USER"
    newgrp docker

    log_message "INFO" "Docker successfully installed and added to user group"
}

install_Eduroam() {
    # verify_env function if return 1 then exit
    verify_env || return

    # Verify if Eduroam configuration is already installed
    if nmcli connection show | grep -q "eduroam"; then
        log_message "INFO" "Eduroam configuration is already exist"
        return
    fi

    # Verify if existing eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py
    if [ -f "eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py" ]; then
        log_message "INFO" "eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py script exists"

        python3 eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py -u "$EDUROAM_USERNAME" -p "$EDUROAM_PASSWORD"
        log_message "INFO" "eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py successfully executed"
    else
        # Download eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py
        log_message "ERROR" "The script eduroam-linux-UdSdF-Eduroam_Docenti_e_PTA.py does not exist"
        return
    fi
    
}

# Install kubectl
install_kubectl() {
    # Verify if kubectl is already installed
    apt_is_installed "kubectl" && return

    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    # Verify the kubectl binary
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
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
        return
    fi
}

# Install Node.js
install_NodeJS() {
    # Verify if Node.js is already installed
    apt_is_installed "node" && return

    # Download and install Node.js
    curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash -

    apt_get_install nodejs
    log_message "INFO" "Node.js successfully installed with the version $(node -v)"

    npm install -g npm@latest
    log_message "INFO" "Npm successfully updated with the version $(npm -v)"
}

install_Spotify() {
    # Verify if Spotify is already installed
    apt_is_installed "spotify" && return

    # Add the Spotify repository signing keys to be able to verify downloaded packages
    curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg

    # Add the Spotify repository
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

    # Update list of available packages
    sudo apt-get update

    # Install Spotify
    apt_get_install spotify-client
    log_message "INFO" "Spotify successfully installed"
}

intall_SQLite_CLI() {
    # Verify if SQLite is already installed
    apt_is_installed "sqlite3" && return

    # Install SQLite
    apt_get_install sqlite3
    log_message "INFO" "SQLite CLI successfully installed"
}

install_browser-SQLite() {
    apt_is_installed "sqlitebrowser" && return

    apt_get_install sqlitebrowser
    log_message "INFO" "SQLite Browser successfully installed"
}

install_AzureStorageExplorer() {
    # Verify if Azure Storage Explorer is already installed
    snap_is_installed "storage-explorer" && return

    sudo snap install storage-explorer

    # Connect to password-manager-service interface
    snap connect storage-explorer:password-manager-service :password-manager-service 

    # Create an executable run script
    touch ~/.snap-connect.sh
    echo "#!/bin/bash
snap connect storage-explorer:password-manager-service :password-manager-service" > ~/.snap-connect.sh

    # Make the script executable
    chmod +x ~/.snap-connect.sh

    # Make it run on startup
    touch ~/.config/autostart/snap-connect.sh.desktop
    echo "[Desktop Entry]
Exec=/home/$USER/.snap-connect.sh
Icon=dialog-scripts
Name=snap-connect.sh
Type=Application
X-KDE-AutostartScript=true" > ~/.config/autostart/snap-connect.sh.desktop

    log_message "INFO" "Azure Storage Explorer successfully installed"
}


install_Microk8s() {
    # Verify if Microk8s is already installed
    snap_is_installed "microk8s" && return

    sudo snap install microk8s --classic

    # Add to the user group
    sudo usermod -a -G microk8s $USER
    mkdir -p ~/.kube
    chmod 0700 ~/.kube

    # Verify the installation
    microk8s status --wait-ready    
}

# Show help message
show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "This script installs various software tools interactively or all at once. It can also exclude specific software."
    echo "The script is designed for Debian-based distributions."
    echo
    echo "Options:"

    # Use an associative array to group flags by their function
    declare -A flag_groups

    # Populate flag_groups with each action as a key and the associated flags as values
    for flag in "${!FLAGS_DECLARATION[@]}"; do
        action="${FLAGS_DECLARATION[$flag]}"
        if [[ -n "${flag_groups[$action]}" ]]; then
            flag_groups["$action"]+=", $flag"
        else
            flag_groups["$action"]="$flag"
        fi
    done

    # Define a column width for the flag display
    local column_width=50

    # Display grouped flags with descriptions, aligned in columns
    for action in "${!flag_groups[@]}"; do
        case "$action" in
            "all")
                printf "  %-*s %s\n" "$column_width" "${flag_groups[$action]}" "# Install all software tools without prompts"
                ;;
            "all-excluding")
                printf "  %-*s %s\n" "$column_width" "${flag_groups[$action]} [software...]" "# Install all except specified software"
                ;;
            "install")
                printf "  %-*s %s\n" "$column_width" "${flag_groups[$action]} [software...]" "# Specify software to install (use one or more names)"
                ;;
            "help")
                printf "  %-*s %s\n" "$column_width" "${flag_groups[$action]}" "# Show this help message"
                ;;
        esac
    done

    echo
    echo "Software options for --${FLAGS_DECLARATION["-i"]} and --${FLAGS_DECLARATION["-ax"]}:"
    # Display each software, its description, and link
    for software in "${!INSTALL_FUNCTIONS[@]}"; do
        local description="${DESCRIPTION_SOFTWARE_LIST[$software]}"
        local link="${LINK_SOFTWARE_LIST[$software]}"
        printf "  %-*s %s %s\n" "$column_width" "${software}" "# $description" "${link}"
    done
    echo
    echo "Example usage:"
    printf "  %-*s %s\n" "$column_width" "$0 -ax Brave Docker" "# Install all except Brave and Docker"
    printf "  %-*s %s\n" "$column_width" "$0 -i Brave Docker" "# Install only Brave and Docker"
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

# Install softwares based on user input
install_functions() {
    update_upgrade

    if [[ "$1" == "all" ]]; then
        local total_packages=${#INSTALL_FUNCTIONS[@]}
        local installed_count=0
        for software in "${!INSTALL_FUNCTIONS[@]}"; do
            #${INSTALL_FUNCTIONS[$software]}  # Original line
            install_one_function "$software" >> "$LOG_FILE" 2>&1 # This line is for progress bar but doesn't print the logs on the terminal, instead it prints on the log file
        done
        echo "" 
        log_message "INFO" "Installation completed: 100%"
        return
    elif [[ "$1" == "all-excluding" ]]; then
        shift
        local exclude=("$@")
        for software in "${!INSTALL_FUNCTIONS[@]}"; do
            if [[ ! " ${exclude[*]} " =~ ${software} ]]; then
                log_message "INFO" "Installing $software in progress..."
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
                log_message "INFO" "Installing $software in progress..."
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
    #restart_session
}

main "$@"