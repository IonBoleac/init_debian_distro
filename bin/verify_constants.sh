#!/bin/bash
source ./config/constants.sh
# ========= Script to verify if the SOFTWARE_DETAILS array is correctly populated =========

# Flag to indicate if any entry is invalid
flag=0

# Function to validate URL format
validate_url() {
    local url=$1
    if [[ $url =~ ^https?://[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})?(:[0-9]{1,5})?(/.*)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate each entry
validate_entry() {
    local key=$1
    local value=$2

    # Split the value into its components
    IFS=';' read -r install_function install_method description link <<< "$value"

    # Check if all components are present
    if [[ -z $install_function || -z $install_method || -z $description || -z $link ]]; then
        echo "Error: Entry for '$key' is missing one or more components."
        flag=1
        return 1
    fi

    # Validate install_method
    if ! [[ $install_method =~ ^(apt|snap|curl|script|tar|test)$ ]]; then
        echo "Error: Invalid install_method '$install_method' for '$key'."
        flag=1
        return 1
    fi

    # Validate URL format
    if ! validate_url "$link"; then
        echo "Error: Invalid URL '$link' for '$key'."
        flag=1
        return 1
    fi
    #return 1
}

# Iterate over the associative array and validate each entry
for key in "${!SOFTWARE_DETAILS[@]}"; do
    validate_entry "$key" "${SOFTWARE_DETAILS[$key]}"
done

if [[ $flag -eq 0 ]]; then
    echo "All entries are valid."
else
    echo "One or more entries are invalid"
    exit 1
fi