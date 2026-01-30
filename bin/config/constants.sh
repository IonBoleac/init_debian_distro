#!/bin/bash

# Declare SOFTWARE_DETAILS and populate it with software details
# format: ["name of the software"]="install_function;install_method;description;link"
declare -A SOFTWARE_DETAILS=(
    ["VSCode"]="install_VSCode;apt;Popular code editor for developers.;https://code.visualstudio.com/"
    ["Brave"]="install_Brave;apt;Privacy-focused web browser.;https://brave.com/"
    ["Docker"]="install_Docker;apt;Platform for building, sharing, and running applications with containers.;https://www.docker.com/"
    #["Eduroam"]="install_Eduroam;script;Secure, worldwide roaming access service developed for the international research and education community.;https://eduroam.org/"
    ["kustomize"]="install_kustomize;curl;Customization of Kubernetes YAML configurations.;https://kubectl.docs.kubernetes.io/installation/kustomize/"
    ["kubectl"]="install_kubectl;curl;command-line tool for controlling Kubernetes clusters.;https://kubernetes.io/docs/reference/kubectl/"
    ["Node.js"]="install_NodeJS;curl;JavaScript runtime built on Chrome's V8 JavaScript engine.;https://nodejs.org/en/"
    ["Spotify"]="install_Spotify;apt;Digital music streaming service.;https://open.spotify.com/intl-it"
    ["SQLite CLI"]="intall_SQLite_CLI;apt;command-line interface for SQLite.;https://sqlite.org/cli.html"
    ["SQLite Browser"]="install_browser-SQLite;apt;Visual tool to create, design, and edit database files compatible with SQLite.;https://sqlitebrowser.org/dl/"
    ["AzureStorageExplorer"]="install_AzureStorageExplorer;snap;Standalone app that makes it easy to work with Azure Storage data on Windows, macOS, and Linux.;https://azure.microsoft.com/en-us/products/storage/storage-explorer" 
    ["Microk8s"]="install_Microk8s;snap;Lightweight Kubernetes for workstations and appliances.;https://microk8s.io/"
    ["GO"]="install_GO;tar;Open-source programming language that makes it easy to build simple, reliable, and efficient software. GO version: go1.23.2 linux/amd64 from tar file;https://golang.org/"
    ["kind"]="install_kind;curl;Tool for running local Kubernetes clusters using Docker container nodes.;https://kind.sigs.k8s.io/"
    ["Helm"]="install_helm;curl;Package manager for Kubernetes.;https://helm.sh/"
    ["nvm"]="install_nvm;curl;Node Version Manager - manages multiple Node.js versions.;https://github.com/nvm-sh/nvm#installing-and-updating"
    ["k9s"]="install_k9s;wget;Kubernetes CLI to manage and observe your clusters in style.;https://github.com/derailed/k9s"
    ["argocd"]="install_argocd;wget;Argo CD CLI tool.;https://argo-cd.readthedocs.io/en/stable/cli_installation/"
    ["argocd-autopilot"]="install_argocd_autopilot;curl;Argo CD Autopilot CLI tool.;https://argoproj-labs.github.io/argocd-autopilot/"
    #["test"]="test;test;test;test"
)
export SOFTWARE_DETAILS

# Flag mappings for parsing
declare -A FLAGS_DECLARATION=(
    ["--all"]="all"
    ["-a"]="all"
    ["--all-excluding"]="all-excluding"
    ["-ax"]="all-excluding"
    ["--install"]="install"
    ["-i"]="install"
    ["--dry-run"]="dry-run"
    ["-d"]="dry-run"
    ["--help"]="help"
    ["-h"]="help"
)
export FLAGS_DECLARATION

# Use an associative array to group flags by their function
declare -A FLAG_GROUPS

# Populate FLAG_GROUPS with each action as a key and the associated flags as values
for flag in "${!FLAGS_DECLARATION[@]}"; do
    action="${FLAGS_DECLARATION[$flag]}"
    if [[ -n "${FLAG_GROUPS[$action]}" ]]; then
        FLAG_GROUPS["$action"]+=", $flag"
    else
        FLAG_GROUPS["$action"]="$flag"
    fi
done
export FLAG_GROUPS

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
export INSTALL_FUNCTIONS
export METHOD_SOFTWARE_LIST
export DESCRIPTION_SOFTWARE_LIST
export LINK_SOFTWARE_LIST

# Constants
LOG_FILE="logs.log"
export LOG_FILE
export LOG_FILE

COLUMN_WIDTH=40 # column width variable needed to show correctly the helper function
export COLUMN_WIDTH

# commands needed to run the script like wget, curl save in a variable
COMMANDS="wget curl git"
export COMMANDS

# Declare the functions to install the software
INSTALL_FUNCTION_SCRIPT="bin/install_softwares.sh"
export INSTALL_FUNCTION_SCRIPT


