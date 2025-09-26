#!/bin/bash
################################################################################
# Created by:  K7-Avenger                                                      #
# For:         Personal use                                                    #
#                                                                              #
# Purpose:     Deploy an instance of Wazah to serve as an in-house SIEM/XDR    #
# solution for a test lab simulating the environment of a small organization.  #
# This script may not be not suited for commercial deployment, use at your own #
# risk. Target distro is Ubuntu 24.04, may not work on other distros.          #
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

INSTALL_DIR="/app"

#The purpose of this function is to check if the script is being executed with
#root/admin permissions. This is required for certian aspects of the script.
check-for-admin(){
  if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Use sudo or switch to the root user."
    exit 1
  fi
}

perform-system-updates(){
  sudo apt-get update && apt-get upgrade -y
}

#The purpose of this function is to download the Wazuh isntallation script from
#official source and place it in the defined directory.
download-app-files(){
  wget -P $INSTALL_DIR wazuh-install.sh https://packages.wazuh.com/4.13/wazuh-install.sh
}

#The purpose of this function is to run the downloaded installation file
run-installer(){
  sudo chmod +x $INSTALL_DIR/wazuh-install.sh
  sudo bash $INSTALL_DIR/wazuh-install.sh -a
  sudo chmod 440 $INSTALL_DIR/wazuh-install.sh
}

#The purpose of this function is to disable Wazuh updates as the updates may 
#break the environment. While this is a recomended action by Wazuh, users
#are encouraged to follow best practices and any applicable rules, regulations,
#and/or organizational policies.
diable-wazuh-updates(){
  sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list
  apt update
}





main(){
  check-for-admin
  perform-system-updates
  mkdir $INSTALL_DIR
  download-app-files
  run-installer
  #diable-wazuh-updates  Uncomment to disable Wazuh updates
  echo -e -n "${GREEN}"
  echo "RECORD LOGIN CREDENTIALS LISTED ABOVE TO ACCESS THE DASHBOARD"
  echo -e -n "${GREEN}"
  echo -n "Login at https://$(hostname -I | cut -d ' ' -f1):443 with the provided credentials"
  echo -e "${RESET}"
  echo "and click on the Getting Started button."
}

main
