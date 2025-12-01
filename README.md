# Initialize a new Ubuntu based PC
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
   - [k9s](https://github.com/derailed/k9s): Kubernetes CLI to manage and observe your clusters in style.
   - [nvm](https://github.com/nvm-sh/nvm#installing-and-updating): Node Version Manager - manages multiple Node.js versions.
   - [Helm](https://helm.sh/): Package manager for Kubernetes.
   - [Brave](https://brave.com/): Privacy-focused web browser.
   - [kind](https://kind.sigs.k8s.io/): Tool for running local Kubernetes clusters using Docker container nodes.
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
The script is designed for Ubuntu-based distributions.

Options:
  -a, --all                                # Install all software tools without prompts
  -d, --dry-run                            # Preview actions without installing (dry-run mode)
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
  k9s                                      # Kubernetes CLI to manage and observe your clusters in style. https://github.com/derailed/k9s
  nvm                                      # Node Version Manager - manages multiple Node.js versions. https://github.com/nvm-sh/nvm#installing-and-updating
  Helm                                     # Package manager for Kubernetes. https://helm.sh/
  Brave                                    # Privacy-focused web browser. https://brave.com/
  kind                                     # Tool for running local Kubernetes clusters using Docker container nodes. https://kind.sigs.k8s.io/
  Docker                                   # Platform for building, sharing, and running applications with containers. https://www.docker.com/
  AzureStorageExplorer                     # Standalone app that makes it easy to work with Azure Storage data on Windows, macOS, and Linux. https://azure.microsoft.com/en-us/products/storage/storage-explorer

Example usage:
  ./install_softwares.sh -ax Brave Docker  # Install all except Brave and Docker
  ./install_softwares.sh -i Brave Docker   # Install only Brave and Docker
  ./install_softwares.sh -d -i VSCode Docker # Preview installation of VSCode and Docker without installing
  ./install_softwares.sh --dry-run -a      # Preview all installations without executing
```

### Dry-Run Mode
The dry-run mode (`--dry-run` or `-d`) allows you to preview all the operations that would be performed without actually executing them. This is particularly useful for:

- **Previewing installations**: See what software would be installed and what commands would be executed
- **Verifying dependencies**: Check which packages and system commands would be invoked
- **Testing configurations**: Ensure your command flags are correct before running actual installations
- **Educational purposes**: Understand the installation process for each software

When dry-run mode is active, the script will:
- Display all commands that would be executed with `[DRY-RUN]` prefix
- Show package installations, system updates, and configuration changes
- Skip all actual system modifications (no `apt-get install`, no downloads, no file changes)
- Provide a summary at the end with `DRY-RUN MODE COMPLETED`

Example output:
```
2025-12-01 11:46:57: INFO - ========== DRY-RUN MODE: No actual installations will be performed ==========
2025-12-01 11:46:57: INFO - [DRY-RUN] Would update system packages (apt-get update)
2025-12-01 11:46:57: INFO - [DRY-RUN] Would install specified software: Brave
2025-12-01 11:46:57: INFO - [DRY-RUN] Would check if brave-browser is installed
2025-12-01 11:46:57: INFO - [DRY-RUN] Would execute: sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg ...
2025-12-01 11:47:00: INFO - ========== DRY-RUN MODE COMPLETED: Review actions above ==========
```

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Improvements
If you want to add more software or improve the script, you can fork the repo and create a pull request.

## TODO
 - Add more software
 - Add functionality to customize the terminal and the shell
