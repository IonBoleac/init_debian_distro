#!/bin/bash

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