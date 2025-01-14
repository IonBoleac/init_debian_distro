# Initialize a new Debian based PC
When you get a new PC, you need to install some basic software to make it usable. You can use the following repo to install the essential software you need and configure your PC. In this repo there are scripts to install software and configure the PC.

## Available Software Tools to be installed
The following software are supported to be installed by the script:
   - [kubectl](https://kubernetes.io/docs/reference/kubectl/): command-line tool for controlling Kubernetes clusters.
   - [Microk8s](https://microk8s.io/): Lightweight Kubernetes for workstations and appliances.
   - [Node.js](https://nodejs.org/en/): JavaScript runtime built on Chrome's V8 JavaScript engine.
   - [SQLite Browser](https://sqlitebrowser.org/dl/): Visual tool to create, design, and edit database files compatible with SQLite.
   - [SQLite CLI](https://sqlite.org/cli.html): command-line interface for SQLite.
   - [Spotify](https://open.spotify.com/intl-it): Digital music streaming service.
   - [GO](https://golang.org/): Open-source programming language that makes it easy to build simple, reliable, and efficient software. GO version: go1.23.2 linux/amd64 from tar file
   - [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/): Customization of Kubernetes YAML configurations.
   - [VSCode](https://code.visualstudio.com/): Popular code editor for developers.
   - [Brave](https://brave.com/): Privacy-focused web browser.
   - [Docker](https://www.docker.com/): Platform for building, sharing, and running applications with containers.
   - [AzureStorageExplorer](https://azure.microsoft.com/en-us/products/storage/storage-explorer): Standalone app that makes it easy to work with Azure Storage data on Windows, macOS, and Linux.

## Usage
Run the script `run_app.sh` and choose the desired option to configure your PC.

```bash
./run_app.sh
```

After running the script, you will be prompted to choose an option. 

### Install Software Tools Directly
You may use the script install_softwares.sh to run the installation of the software directly.
The script will install the software and configure the PC able to use the software properly. 
In first, you must change working directory using:

```bash
cd bin
```

After that follow the bellow commands to know how to use the install software script directly:

```bash
./install_softwares.sh -h
```

### Help install softwares command output
```bash
Usage: ./install_softwares.sh [options]

This script installs various software tools interactively or all at once. It can also exclude specific software.
The script is designed for Debian-based distributions.

Options:
  -a, --all                                # Install all software tools without prompts
  -i, --install [software...]              # Specify software to install (use one or more names)
  -ax, --all-excluding [software...]       # Install all except specified software
  -h, --help                               # Show this help message

Software options for --install and --all-excluding:
  kubectl                                  # command-line tool for controlling Kubernetes clusters. https://kubernetes.io/docs/reference/kubectl/
  Microk8s                                 # Lightweight Kubernetes for workstations and appliances. https://microk8s.io/
  Node.js                                  # JavaScript runtime built on Chrome's V8 JavaScript engine. https://nodejs.org/en/
  SQLite Browser                           # Visual tool to create, design, and edit database files compatible with SQLite. https://sqlitebrowser.org/dl/
  SQLite CLI                               # command-line interface for SQLite. https://sqlite.org/cli.html
  Spotify                                  # Digital music streaming service. https://open.spotify.com/intl-it
  GO                                       # Open-source programming language that makes it easy to build simple, reliable, and efficient software. GO version: go1.23.2 linux/amd64 from tar file https://golang.org/
  kustomize                                # Customization of Kubernetes YAML configurations. https://kubectl.docs.kubernetes.io/installation/kustomize/
  VSCode                                   # Popular code editor for developers. https://code.visualstudio.com/
  Brave                                    # Privacy-focused web browser. https://brave.com/
  Docker                                   # Platform for building, sharing, and running applications with containers. https://www.docker.com/
  AzureStorageExplorer                     # Standalone app that makes it easy to work with Azure Storage data on Windows, macOS, and Linux. https://azure.microsoft.com/en-us/products/storage/storage-explorer

Example usage:
  ./install_softwares.sh -ax Brave Docker  # Install all except Brave and Docker
  ./install_softwares.sh -i Brave Docker   # Install only Brave and Docker
```

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Improvements
If you want to add more software or improve the script, you can fork the repo and create a pull request.

## TODO
 - Add more software
 - Add functionality to customize the terminal and the shell
