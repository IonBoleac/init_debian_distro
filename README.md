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
Run the following commands to know how to use the install software script directly:

```bash
./bin/install_softwares.sh -h
```

### Help install softwares command output
```bash

```

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Improvements
If you want to add more software or improve the script, you can fork the repo and create a pull request.

## TODO
 - Add more software
 - Add functionality to customize the terminal and the shell
