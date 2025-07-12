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

  #update .env file values (overwrite default DB uname/passwd)
	#passwd_1get immich-db-uname from user
	
  

}

update-env-file(){
  PASSWORD_1=$(systemd-ask-password "Enter new database password: ")
  PASSWORD_2=$(systemd-ask-password "Confirm new password: ")
  ENV_FILE="/$INSTALL_DIR/example.env"
  TARGET_VAR="DB_PASSWORD"
  
  while [[ "$PASSWORD_1" != "$PASSWORD_2" ]]; do
  	echo "Passwords do not match."
  	read -p "Would you like to try again? (y/n): " choice
  
  	case "$choice" in
  		[Nn]*)
  			exit 1
  			unset PASSWORD_1
  			unset PASSWORD_2
  			;;
  		[Yy]*)
  			PASSWORD_1=$(systemd-ask-password "Enter new database password: ")
  			PASSWORD_2=$(systemd-ask-password "Confirm new password: ")
  			;;
  		*)
  			echo "Invalid input, please use 'y' or 'n'. "
  			;;
  	esac
  done
  
  sed -i.bak "s/^${TARGET_VAR}=.*/${TARGET_VAR}=${PASSWORD_1}/" "$ENV_FILE"
  
  unset PASSWORD_1
  unset PASSWORD_2
}

main(){
  mkdir $INSTALL_DIR
  resolve-docker-dependancies
  download-immich-files
  update-env-file

}

main
