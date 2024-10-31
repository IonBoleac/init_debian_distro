import re

PATH_SCRIPT="install_softwares.sh"

def parse_bash_script(bash_file_path):
    software_list_name = []
    software_list_info = []
    inside_install_section = False
    with open(bash_file_path, 'r') as bash_file:
        for line in bash_file:
            if 'declare -A SOFTWARE_DETAILS' in line:
                inside_install_section = True
            elif 'declare -A FLAGS_DECLARATION' in line:
                inside_install_section = False
            if inside_install_section:
                match = re.match(r'\s*\["([^"]+)"\]=\"([^"]+)\"', line)
                if match:
                    software_name = match.group(1)
                    software_info = match.group(2)
                    software_list_name.append(software_name)
                    software_list_info.append(software_info)
    return software_list_name, software_list_info

# Create markdown content dynamically
def create_markdown(path_script=PATH_SCRIPT):
    def split_info(info):
        return [info.split(';') for info in software_list_info]

    softwares_list_name, software_list_info = parse_bash_script(path_script)

    splitted_info = [info.split(';') for info in software_list_info]

    

    markdown_content = """
# Initialize a new Debian based PC
When you get a new PC, you need to install some basic software to make it usable. You can use the following repo to install the essential software you need and configure your PC.

## Software
The following software are supported by the script:
"""
    # Add software list dynamically
    for idx, software in enumerate(softwares_list_name):

        #markdown_content += f"- {software} " + ", ".join(info if info else "NN" for _, info in enumerate(splitted_info[idx])) + "\n"
        markdown_content += f"- [{software}]({splitted_info[idx][3]}): {splitted_info[idx][2]}\n"
    markdown_content += f"""

## Usage
To use the script, you need to clone the repo and run the script. The script will install the software and configure the PC. 
Run the following commands to know how to use the script:

```bash
./{PATH_SCRIPT} -h
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


def main(path_script=PATH_SCRIPT):
    # Write the markdown content to a file
    def write_markdown_to_file(filename, content):
        with open(filename, 'w') as file:
            file.write(content)

    # Generate the markdown content
    markdown_content = create_markdown()

    # Write the markdown content to README.md
    write_markdown_to_file("README1.md", markdown_content)

    print("README.md file has been generated successfully.")

if __name__ == "__main__":
    main()