#!/bin/bash
################################################################################
# Created by:  K7-Avenger                                                      #
# For:         Personal use                                                    #
#                                                                              #
# Purpose:     Deploy and instance of Immich to serve as a replacement for     #
# Google Photos in a home use setting. DUE TO ONGOING DEVELOPMENT OF Immich,   #
# this script is not suited for commercial deployment. Target distro is        #
# Ubuntu 24.04, may not work on other distros.                                 #
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

INSTALL_DIR="./immich-app"

resolve-docker-dependancies(){
  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  # Install latest version of docker:
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Verify successful installation:
  sudo docker run hello-world
}

download-immich-files(){
  wget -P /$INSTALL_DIR/ docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
  wget -P /$INSTALL_DIR/ https://github.com/immich-app/immich/releases/latest/download/example.env
  
}
