import re

def parse_bash_script(bash_file_path):
    install_softwares = []
    inside_install_section = False
    with open(bash_file_path, 'r') as bash_file:
        for line in bash_file:
            if 'declare -A INSTALL_FUNCTIONS' in line:
                inside_install_section = True
            elif 'declare -A FLAGS_DECLARATION' in line:
                inside_install_section = False
            if inside_install_section:
                match = re.match(r'\s*\["([^"]+)"\]=\"([^"]+)\"', line)
                if match:
                    software_name = match.group(1)
                    install_softwares.append(software_name)
    return install_softwares

# Create markdown content dynamically
def create_markdown(install_functions):
    markdown_content = """
# Initialize a new Debian based PC
When you get a new PC, you need to install some basic software to make it usable. You can use the following repo to install the essential software you need and configure your PC.

## Software
The following software are supported by the script:
"""
    # Add software list dynamically
    for software in install_functions:
        markdown_content += f"- {software}\n"

    markdown_content += """

## Usage
To use the script, you need to clone the repo and run the script. The script will install the software and configure the PC. 
Run the following commands to know how to use the script:

```bash
./install_softwares.sh -h
```

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Improvements
If you want to add more software or improve the script, you can fork the repo and create a pull request.

## TODO
 - Add more software
 - Add functionality to customize the terminal and the shell
"""
    return markdown_content

# Write the markdown content to a file
def write_markdown_to_file(filename, content):
    with open(filename, 'w') as file:
        file.write(content)

softwares_list = parse_bash_script("install_softwares.sh")


# Generate the markdown content
markdown_content = create_markdown(softwares_list)

# Write the markdown content to README.md
write_markdown_to_file("README1.md", markdown_content)

print("README.md file has been generated successfully.")
