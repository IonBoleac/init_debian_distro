#!/bin/bash

# Load constants from the constants.sh file
source constants.sh

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

# Declare an array that store all the eventual failed installations
declare -a FAILED_INSTALLATIONS

# Declare additional arrays to store install functions, methods, descriptions, and links
declare -A INSTALL_FUNCTIONS
declare -A METHOD_SOFTWARE_LIST
declare -A DESCRIPTION_SOFTWARE_LIST
declare -A LINK_SOFTWARE_LIST

# Populate all arrays in one loop
for software in "${!SOFTWARE_DETAILS[@]}"; do
    # Split the details based on semicolons
    IFS=';' read -r install_function install_method description link <<< "${SOFTWARE_DETAILS[$software]}"
    
    # Populate each array with corresponding data
    INSTALL_FUNCTIONS["$software"]="$install_function"
    METHOD_SOFTWARE_LIST["$software"]="$install_method"
    DESCRIPTION_SOFTWARE_LIST["$software"]="$description"
    LINK_SOFTWARE_LIST["$software"]="$link"
done

# Example usage: Access install function, method, description, and link for a software
get_install_function() {
    local software=$1
    echo "${INSTALL_FUNCTIONS[$software]}"
}

get_install_method() {
    local software=$1
    echo "${METHOD_SOFTWARE_LIST[$software]}"
}

get_software_description() {
    local software=$1
    echo "${DESCRIPTION_SOFTWARE_LIST[$software]}"
}

get_software_link() {
    local software=$1
    echo "${LINK_SOFTWARE_LIST[$software]}"
}


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

# Install GO from tar file
install_GO() {
    local GO_DIRECTORY="$HOME/go"
    local GO_VERSION=1.23.2
    local GO_TAR_FILE="go$GO_VERSION.linux-amd64.tar.gz"
    local GO_URL="https://go.dev/dl/$GO_TAR_FILE"

    log_message "INFO" "Installing GO in progress... Install GO version: $GO_TAR_FILE from a tar file"
    log_message "INFO" "Installing it in local directory: $GO_DIRECTORY"

    # Verify if GO already exists
    if find "$GO_DIRECTORY" -type d -print -quit; then
        log_message "INFO" "GO directory already exists with version: $GO_VERSION."
        return
    fi

    verify_command "wget $GO_URL"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download GO $GO_TAR_FILE tar file"
        FAILED_INSTALLATIONS+=("GO")
        return
    fi

    tar -xzf $GO_TAR_FILE
    cp -r go ~/
    rm -rf go $GO_TAR_FILE
    rm -rf go

    # Add GO to PATH in .bashrc
    echo "export GOPATH=$GO_DIRECTORY" >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc

    # reload .bashrc
    source ~/.bashrc
}

# Install VSCode
install_VSCode() {
    log_message "INFO" "Installing VSCode in progress..."
    # Verify if VSCode is already installed
    is_installed "code" && return

    # Download and install VSCode
    verify_command "wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb"

    # verify if the download was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download VSCode"
        FAILED_INSTALLATIONS+=("VSCode")
        return
    fi

    verify_command "sudo dpkg -i vscode.deb"

    # verify if the installation was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install VSCode"
        FAILED_INSTALLATIONS+=("VSCode")
        return
    fi

    echo "VSCode installed"
    log_message "INFO" "VSCode successfully installed"
}

install_Brave() {
    log_message "INFO" "Installing Brave in progress..."
    # Verify if Brave is already installed
    is_installed "brave-browser" && return

    # Download and install Brave
    verify_command "sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Brave keyring"
        FAILED_INSTALLATIONS+=("Brave")
        return
    fi
    
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt-get update
    apt_get_install brave-browser

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Brave"
        FAILED_INSTALLATIONS+=("Brave")
        return
    fi

    log_message "INFO" "Brave successfully installed"
}

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

install_Eduroam() {
    log_message "INFO" "Installing Eduroam in progress..."
    # verify_env function if return 1 then exit
    verify_env || return

    # Verify if Eduroam configuration is already installed
    if nmcli connection show | grep -q "eduroam"; then
        log_message "INFO" "Eduroam configuration is already exist"
        FAILED_INSTALLATIONS+=("Eduroam")
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
        FAILED_INSTALLATIONS+=("Eduroam")
        return
    fi
    
}

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

# Install Node.js
install_NodeJS() {
    log_message "INFO" "Installing Node.js in progress..."
    # Verify if Node.js is already installed
    is_installed "node" && return

    # Download and install Node.js
    verify_command "curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash -"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Node.js setup script"
        FAILED_INSTALLATIONS+=("Node.js")
        return
    fi

    verify_command "apt_get_install nodejs"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Node.js"
        FAILED_INSTALLATIONS+=("Node.js")
        return
    fi

    log_message "INFO" "Node.js successfully installed with the version $(node -v)"

    npm install -g npm@latest
    log_message "INFO" "Npm successfully updated with the version $(npm -v)"
}

install_Spotify() {
    log_message "INFO" "Installing Spotify in progress..."
    # Verify if Spotify is already installed
    is_installed "spotify" && return

    # Add the Spotify repository signing keys to be able to verify downloaded packages
    verify_command "curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Spotify repository signing keys"
        FAILED_INSTALLATIONS+=("Spotify")
        return
    fi

    # Add the Spotify repository
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

    # Update list of available packages
    sudo apt-get update

    # Install Spotify
    verify_command "sudo apt-get install spotify-client -y"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Spotify"
        FAILED_INSTALLATIONS+=("Spotify")
        return
    fi
    log_message "INFO" "Spotify successfully installed"
}

intall_SQLite_CLI() {
    log_message "INFO" "Installing SQLite CLI in progress..."
    # Verify if SQLite is already installed
    is_installed "sqlite3" && return

    # Install SQLite
    verify_command "sudo apt-get install sqlite3 -y"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install SQLite"
        FAILED_INSTALLATIONS+=("SQLite")
        return
    fi

    log_message "INFO" "SQLite CLI successfully installed"
}

install_browser-SQLite() {
    log_message "INFO" "Installing SQLite Browser in progress..."
    is_installed "sqlitebrowser" && return

    verify_command "sudo apt-get install sqlitebrowser -y"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install SQLite Browser"
        FAILED_INSTALLATIONS+=("SQLite Browser")
        return
    fi
    log_message "INFO" "SQLite Browser successfully installed"
}

install_AzureStorageExplorer() {
    log_message "INFO" "Installing Azure Storage Explorer in progress..."
    # Verify if Azure Storage Explorer is already installed
    is_installed "storage-explorer" && return

    verify_command "sudo snap install storage-explorer"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Azure Storage Explorer"
        FAILED_INSTALLATIONS+=("Azure Storage Explorer")
        return
    fi

    # Connect to password-manager-service interface
    verify_command "sudo snap connect storage-explorer:password-manager-service :password-manager-service"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to connect to password-manager-service interface"
        FAILED_INSTALLATIONS+=("Azure Storage Explorer")
        return
    fi

    # Create an executable run script
    touch ~/.snap-connect.sh

    # verify using ll comand if the file is created


    echo "#!/bin/bash
snap connect storage-explorer:password-manager-service :password-manager-service" > ~/.snap-connect.sh
    
    # Make the script executable
    chmod +x ~/.snap-connect.sh

    # Verify if the .config/autostart directory exists
    if [ ! -d ~/.config/autostart ]; then
        mkdir -p ~/.config/autostart
    fi

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
    log_message "INFO" "Installing Microk8s in progress..."
    # Verify if Microk8s is already installed
    is_installed "microk8s" && return

    verify_command "sudo snap install microk8s --classic"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Microk8s"
        FAILED_INSTALLATIONS+=("Microk8s")
        return
    fi

    # Add to the user group
    sudo usermod -a -G microk8s $USER
    mkdir -p ~/.kube
    chmod 0700 ~/.kube

    # Verify the installation
    microk8s status --wait-ready    

    log_message "INFO" "Microk8s successfully installed. Restart your session to apply changes."
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

    # Display grouped flags with descriptions, aligned in columns
    for action in "${!flag_groups[@]}"; do
        case "$action" in
            "all")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${flag_groups[$action]}" "# Install all software tools without prompts"
                ;;
            "all-excluding")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${flag_groups[$action]} [software...]" "# Install all except specified software"
                ;;
            "install")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${flag_groups[$action]} [software...]" "# Specify software to install (use one or more names)"
                ;;
            "help")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${flag_groups[$action]}" "# Show this help message"
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