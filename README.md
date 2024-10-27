# Initilize a new Debian based PC
When you get a new PC, you need to install some basic software to make it usable. You can use the following repo to install the essential software you need and configure your PC.

## Software
The following software are supported by the script:
 - [Visual Studio Code](https://code.visualstudio.com/)
 - [Brave Browser](https://brave.com/)
 - [Docker](https://www.docker.com/) 
 - [kubectl](https://kubernetes.io/docs/reference/kubectl/) CLI tool for Kubernetes.
 - [Eduroam](https://eduroam.org/) configuration to connect on the university network (only for students of the University of Ferrara). You can change the configuration file to connect to your network provided by your university.
 - [Spotify](https://www.spotify.com/)
 - [Node.js](https://nodejs.org/en/) 


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
 - Add functionality to custom the terminal and the shell