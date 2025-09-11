#!/bin/bash
################################################################################
# Created by:  K7-Avenger                                                      #
# For:         Personal use                                                    #
#                                                                              #
# Purpose:     Deploy and instance of RustDesk as a testbed for a jump-box     #
# style VM so that users can access VMs on another subnet/VLAN                 #
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

#INSTALL_DIR="/immich-app"

#The purpose of this function is to check if the script is being executed with
#root/admin permissions. This is required for certian aspects of the script.
check-for-admin(){
  if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Use sudo or switch to the root user."
    exit 1
  fi
}

#The purpose of this function is to download and install the docker related
#dependancies required to run Immich.
resolve-docker-dependancies(){
  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install ca-certificates curl -y
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
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

  # Verify successful installation:
  sudo docker run hello-world
}

download-rustdesk-files(){
#  wget -P /$INSTALL_DIR/ docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
#  wget -P /$INSTALL_DIR/ https://github.com/immich-app/immich/releases/latest/download/example.env
}



main(){
  check-for-admin
  mkdir $INSTALL_DIR
  resolve-docker-dependancies
  download-rustdesk-files
  sudo docker compose up -d
  #Add a health-check here prior to displaying next-steps
  echo "To register for the admin user, access the web application at "
  echo -e -n "${GREEN}"
  echo -n "http://$(hostname -I | cut -d ' ' -f1):2283"
  echo -e "${RESET}"
  echo "and click on the Getting Started button."
}

main
