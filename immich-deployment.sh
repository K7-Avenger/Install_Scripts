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

INSTALL_DIR="/immich-app"

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

download-immich-files(){
  wget -P /$INSTALL_DIR/ docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
  wget -P /$INSTALL_DIR/ https://github.com/immich-app/immich/releases/latest/download/example.env

  #update .env file values (overwrite default DB uname/passwd)
	#passwd_1get immich-db-uname from user
	
  

}

#The purpose of this function is to ask the user to enter a new (non-default)
#password for the Immich database and update the corrisponding .env file.
update-env-file(){  
  TARGET_VAR_UPLOAD="UPLOAD_LOCATION"
  UPLOAD_DIR="$INSTALL_DIR/library"
  TARGET_VAR_DATA="DB_DATA_LOCATION"
  DB_DATA_DIR="$INSTALL_DIR/postgres"
  TARGET_VAR_PASSWD="DB_PASSWORD"

  PASSWORD_1=$(systemd-ask-password "Enter new database password: ")
  PASSWORD_2=$(systemd-ask-password "Confirm new password: ")
  ENV_FILE="$INSTALL_DIR/example.env"
    
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

  sed -i.bak "s|^${TARGET_VAR_UPLOAD}=.*|${TARGET_VAR_UPLOAD}=${UPLOAD_DIR}|" "$ENV_FILE"
  sed -i "s|^${TARGET_VAR_DATA}=.*|${TARGET_VAR_DATA}=${DB_DATA_DIR}|" "$ENV_FILE"
  sed -i "s/^${TARGET_VAR_PASSWD}=.*/${TARGET_VAR_PASSWD}=${PASSWORD_1}/" "$ENV_FILE"
  sed -i "s/^# TZ=Etc\/UTC$/TZ=Cst\/UTC/" $ENV_FILE
  
  unset PASSWORD_1
  unset PASSWORD_2
  chmod 440 $ENV_FILE
  mv $ENV_FILE $INSTALL_DIR/.env
}

main(){
  check-for-admin
  mkdir $INSTALL_DIR
  resolve-docker-dependancies
  download-immich-files
  update-env-file
  sudo docker compose up -d
  echo "To register for the admin user, access the web application at "
  echo -e -n "${GREEN}"
  echo -n "http://$(hostname -I | cut -d ' ' -f1):2283"
  echo -e "${RESET}"
  echo -n "and click on the Getting Started button."
}

main
