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
    markdown_content="# Initialize a new Debian based PC
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
