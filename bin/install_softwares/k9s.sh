#!/bin/bash
# script to installa k9s

install_k9s() {
    log_message "INFO" "Installing k9s in progress..."
    # Verify if k9s is already installed
    is_installed "k9s" && return

    local KARCH
    KARCH="$(dpkg --print-architecture)"   # amd64 / arm64
    local K9S_DEB="k9s_linux_${KARCH}.deb"

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would download ${K9S_DEB} from GitHub"
        log_message "INFO" "[DRY-RUN] Would install k9s package"
        log_message "INFO" "[DRY-RUN] Would verify k9s installation"
        log_message "INFO" "k9s successfully installed and configured"
        return
    fi

    verify_command "wget https://github.com/derailed/k9s/releases/latest/download/${K9S_DEB} && sudo apt install -y ./${K9S_DEB} && rm ${K9S_DEB}"

    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install k9s. Check logs for details or download manually from https://github.com/derailed/k9s"
        FAILED_INSTALLATIONS+=("k9s")
        rm -f "${K9S_DEB}"
        return
    fi

    # Verify installation
    if command -v k9s &> /dev/null; then
        k9s version
        log_message "INFO" "k9s successfully installed and configured"
    else
        log_message "ERROR" "k9s installation completed but command not found in PATH"
        FAILED_INSTALLATIONS+=("k9s")
        return
    fi

    # Copia i plugin k9s nella config dir corretta (idempotente)
    local K9S_CFG="$HOME/.config/k9s"
    local PLUGINS_SRC="${PARENT_DIRECTORY:-$(cd "$(dirname "$0")/../.." && pwd)}/bin/config/k9s/plugins"
    if [ -d "$PLUGINS_SRC" ]; then
        mkdir -p "$K9S_CFG"
        if cp -r "$PLUGINS_SRC" "$K9S_CFG/"; then
            log_message "INFO" "k9s plugins successfully copied to $K9S_CFG/plugins"
        else
            log_message "ERROR" "Failed to copy k9s plugins to $K9S_CFG/plugins"
        fi
    else
        log_message "INFO" "k9s plugins source not found, skipping copy"
    fi
}