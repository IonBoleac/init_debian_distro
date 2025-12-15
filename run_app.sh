#!/bin/bash

source ./bin/config/constants.sh

export PARENT_DIRECTORY="$(pwd)"

help_message_install_software() {
    echo
    echo "Choosen script to install softwares!"
    echo "Possible flags are:"
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
            "dry-run")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${FLAG_GROUPS[$action]}" "# Preview actions without installing (dry-run mode)"
                ;;
            "help")
                printf "  %-*s %s\n" "$COLUMN_WIDTH" "${FLAG_GROUPS[$action]}" "# Show this help message"
                ;;
        esac
    done
    echo
    echo "With the following software tools available:"
    # Display software tools with descriptions, aligned in columns
    for software in "${!SOFTWARE_DETAILS[@]}"; do
        printf "  %-*s %s\n" "$COLUMN_WIDTH" "$software" "${DESCRIPTION_SOFTWARE_LIST[$software]}"
    done
    echo
    echo "Example usage:"
    printf "  %-*s %s\n" "$COLUMN_WIDTH" "-ax Brave Docker" "# Install all except Brave and Docker"
    printf "  %-*s %s\n" "$COLUMN_WIDTH" "-i Brave Docker" "# Install only Brave and Docker"
    printf "  %-*s %s\n" "$COLUMN_WIDTH" "-d -i VSCode Docker" "# Preview VSCode and Docker installation"
    printf "  %-*s %s\n" "$COLUMN_WIDTH" "--dry-run -a" "# Preview all installations"
    echo
    echo "CTRL+C to exit"
}

# Display menu for user to choose actions
while true; do
    cd "$PARENT_DIRECTORY" || exit 1
    echo "Welcome to the setup script!"
    echo "1. Install Software"
    echo "2. Generate README"
    echo "3. Verify Constants"
    echo "4. Config Terminal"
    echo "5. Pre-flight Check"
    echo "9. Exit"

    read -p "Choose an option [1-5, 9]: " choice



    case $choice in
        1)
            # Print the help function of the install_softwares.sh script

            help_message_install_software
            read -p "Input: " flags
            echo "You chose: $flags"
            # Pass the flags to the install_softwares.sh script
            cd bin || exit 1
            echo $PWD
            # shellcheck disable=SC2086
            ./install_softwares.sh $flags
            ;;
        2)
            cd bin || exit 1
            ./auto_gen_readme.sh
            cp -f README.md ../
            rm README.md
            ;;
        3)  
            cd bin || exit 1
            ./verify_constants.sh
            ;;
        4)
            cd bin || exit 1
            
            ./config_terminal.sh
            ;;
        5)
            cd bin || exit 1
            ./preflight_check.sh
            ;;
        9)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac

done