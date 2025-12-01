#!/bin/bash

# Load constants
source ./config/constants.sh

INSTALL_FUNCTION_SCRIPT="install_softwares.sh"

# Function to extract software details by key
get_software_detail() {
    local software_name="$1"
    local field_index="$2"
    IFS=';' read -r -a details <<< "${SOFTWARE_DETAILS[$software_name]}"
    echo "${details[$field_index]}"
}

# Helper functions to get specific fields by index
get_install_function() { get_software_detail "$1" 0; }
get_install_method() { get_software_detail "$1" 1; }
get_description() { get_software_detail "$1" 2; }
get_link() { get_software_detail "$1" 3; }

# Example usage: Accessing details for a software
example_usage() {
    local software="VSCode"
    echo "Software: $software"
    echo "Install Function: $(get_install_function "$software")"
    echo "Install Method: $(get_install_method "$software")"
    echo "Description: $(get_description "$software")"
    echo "Link: $(get_link "$software")"
}

# Main function to display all software details in markdown format
create_markdown() {
    # Begin markdown content
    markdown_content="# Initialize a new Ubuntu based PC
When you get a new PC, you need to install some basic software to make it usable. You can use the following repo to install the essential software you need and configure your PC. In this repo there are scripts to install software and configure the PC.

## Available Software Tools to be installed
The following software are supported to be installed by the script:
"
# Loop through all software and append to markdown content
    for software in "${!SOFTWARE_DETAILS[@]}"; do
        description=$(get_description "$software")
        link=$(get_link "$software")
        markdown_content+="   - [$software]($link): $description\n"
    done
# TODO: Add other software tools to the list and other improvements like customizing the terminal and shell

# Append the usage instructions, license, and improvement sections
    markdown_content+="
## Usage
Run the script \`run_app.sh\` and choose the desired option to configure your PC.

\`\`\`bash
./run_app.sh
\`\`\`

After running the script, you will be prompted to choose an option. 

### Install Software Tools Directly
You may use the script install_softwares.sh to run the installation of the software directly.
The script will install the software and configure the PC able to use the software properly. 
In first, you must change working directory using:

\`\`\`bash
cd bin
\`\`\`

After that follow the bellow commands to know how to use the install software script directly:

\`\`\`bash
./$INSTALL_FUNCTION_SCRIPT -h
\`\`\`

### Help install softwares command output
"
# Append the help command output
    help_output=$(./$INSTALL_FUNCTION_SCRIPT -h)
    markdown_content+="\`\`\`bash\n$help_output\n\`\`\`\n"

markdown_content+="
### Dry-Run Mode
The dry-run mode (\`--dry-run\` or \`-d\`) allows you to preview all the operations that would be performed without actually executing them. This is particularly useful for:

- **Previewing installations**: See what software would be installed and what commands would be executed
- **Verifying dependencies**: Check which packages and system commands would be invoked
- **Testing configurations**: Ensure your command flags are correct before running actual installations
- **Educational purposes**: Understand the installation process for each software

When dry-run mode is active, the script will:
- Display all commands that would be executed with \`[DRY-RUN]\` prefix
- Show package installations, system updates, and configuration changes
- Skip all actual system modifications (no \`apt-get install\`, no downloads, no file changes)
- Provide a summary at the end with \`DRY-RUN MODE COMPLETED\`

Example output:
\`\`\`
2025-12-01 11:46:57: INFO - ========== DRY-RUN MODE: No actual installations will be performed ==========
2025-12-01 11:46:57: INFO - [DRY-RUN] Would update system packages (apt-get update)
2025-12-01 11:46:57: INFO - [DRY-RUN] Would install specified software: Brave
2025-12-01 11:46:57: INFO - [DRY-RUN] Would check if brave-browser is installed
2025-12-01 11:46:57: INFO - [DRY-RUN] Would execute: sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg ...
2025-12-01 11:47:00: INFO - ========== DRY-RUN MODE COMPLETED: Review actions above ==========
\`\`\`

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Improvements
If you want to add more software or improve the script, you can fork the repo and create a pull request.

## TODO
 - Add more software
 - Add functionality to customize the terminal and the shell
"

# return the markdown content
echo -e "$markdown_content"
}

# Function to write the markdown content to README.md
write_markdown_to_file() {
    local filename="README.md"
    local content="$1"

    echo "$content" > "$filename"
    echo "README.md file has been generated successfully."
}

# Main script execution
markdown_content=$(create_markdown)
write_markdown_to_file "$markdown_content"

echo "$markdown_content"
