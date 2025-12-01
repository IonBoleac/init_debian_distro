#!/bin/bash

# Install VSCode
install_VSCode() {
    log_message "INFO" "Installing VSCode in progress..."
    # Verify if VSCode is already installed
    is_installed "code" && return

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download VSCode .deb package"
        log_message "INFO" "[DRY-RUN] Would verify SHA256 checksum from https://code.visualstudio.com/sha"
        log_message "INFO" "[DRY-RUN] Would install VSCode via dpkg"
        log_message "INFO" "VSCode successfully installed"
        return
    fi

    # Download and install VSCode
    verify_command "wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb"

    # verify if the download was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download VSCode. Check your internet connection or download manually from https://code.visualstudio.com/"
        FAILED_INSTALLATIONS+=("VSCode")
        rm -f vscode.deb
        return
    fi

    # Fetch expected SHA256 from Microsoft
    log_message "INFO" "Fetching SHA256 checksum from code.visualstudio.com..."
    
    # Try with jq first, fallback to python3
    if command -v jq &> /dev/null; then
        EXPECTED_SHA=$(curl -fsSL "https://code.visualstudio.com/sha" 2>/dev/null | \
            jq -r '.products[] | select(.platform.os == "linux-deb-x64" and .build == "stable") | .sha256hash' 2>/dev/null)
    elif command -v python3 &> /dev/null; then
        EXPECTED_SHA=$(curl -fsSL "https://code.visualstudio.com/sha" 2>/dev/null | \
            python3 -c "import sys, json; data = json.load(sys.stdin); print(next((p['sha256hash'] for p in data['products'] if p.get('platform', {}).get('os') == 'linux-deb-x64' and p.get('build') == 'stable'), ''))" 2>/dev/null)
    else
        log_message "ERROR" "Neither jq nor python3 found. Cannot verify checksum. Please install jq or python3."
        FAILED_INSTALLATIONS+=("VSCode")
        rm -f vscode.deb
        return
    fi

    # Verify checksum was retrieved
    if [ -z "$EXPECTED_SHA" ] || [ ${#EXPECTED_SHA} -ne 64 ]; then
        log_message "ERROR" "Failed to retrieve valid SHA256 checksum from Microsoft. Cannot verify download integrity."
        FAILED_INSTALLATIONS+=("VSCode")
        rm -f vscode.deb
        return
    fi

    # Calculate actual SHA256
    log_message "INFO" "Verifying checksum..."
    ACTUAL_SHA=$(sha256sum vscode.deb | awk '{print $1}')

    # Compare checksums
    if [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ]; then
        log_message "INFO" "✓ Checksum verification passed"
    else
        log_message "ERROR" "✗ Checksum verification failed! Downloaded file may be corrupted or tampered."
        log_message "ERROR" "Expected: $EXPECTED_SHA"
        log_message "ERROR" "Got:      $ACTUAL_SHA"
        FAILED_INSTALLATIONS+=("VSCode")
        rm -f vscode.deb
        return
    fi

    verify_command "sudo dpkg -i vscode.deb"

    # verify if the installation was successful
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install VSCode. Try running 'sudo apt-get install -f' to fix dependencies, then retry."
        FAILED_INSTALLATIONS+=("VSCode")
        rm -f vscode.deb
        return
    fi

    # Clean up downloaded file
    rm -f vscode.deb

    log_message "INFO" "VSCode successfully installed"
}