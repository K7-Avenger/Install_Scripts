#!/bin/bash
################################################################################
# Created by:  K7-Avenger                                                      #
# For:         Personal use                                                    #
#                                                                              #
# Purpose:     Deployment of LM Studio & Hermes for AI testing.                #
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'


INSTALL_DIR="ai-testing"

#The purpose of this function is to check if the script is being executed with
#root/admin permissions. This may be required for certian aspects of the script.
check-for-admin(){
  if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Use sudo or switch to the root user."
    exit 1
  fi
}

system-update(){
  sudo apt-get update && sudo apt-get upgrade -y
}

create-app-directory(){
  mkdir $INSTALL_DIR
  #chmod 777 $INSTALL_DIR
}

download-dependancies(){
  create-app-directory
  sudo wget -P $INSTALL_DIR https://installers.lmstudio.ai/linux/x64/0.4.16-2/LM-Studio-0.4.16-2-x64.deb
  sudo wget -P $INSTALL_DIR https://hermes-agent.nousresearch.com/install.sh
  chown -R "$SUDO_UID:$SUDO_GID" $INSTALL_DIR

}

validateFileChecksums(){
	#generate installer checksum
	file_checksum=$(sha512sum $INSTALL_DIR/LM-Studio-0.4.16-2-x64.deb | cut -d " " -f1)
	echo "file checksum is: $file_checksum"

	#read checksum provided by Rapid7
	downloaded_checksum=$(wget -qO- https://lmstudio.ai/download | grep -oE '[a-fA-F0-9]{128}' | sed -n '2p')
	echo "provided checksum is: $downloaded_checksum"
	
	#compare checksums, abort installation if they do not match
	if [[ $file_checksum == $downloaded_checksum ]]; then
		echo -e -n "${GREEN}"
		echo "sha512sum match! Install may continue, setting (owner) execute bit..."
		echo -e "${RESET}"
		
		#add execute permissions to .bin installer
		sudo chmod 544 $INSTALL_DIR/LM-Studio-0.4.16-2-x64.deb
	else
		echo -e -n "${RED}"
		echo "sha512sum does not match! Aborting install and setting permissions on installer to 'read-only'."
		echo -e "${RESET}"
		#remove execute permissions to .bin installer
		sudo chmod -x $INSTALL_DIR/LM-Studio-0.4.16-2-x64.deb
		exit 1
	fi
}

install-dependancies(){
  #curl -fsSL https://lmstudio.ai/install.sh | bash #<--llmster is LM Studio's headless daemon for servers, cloud instances, and CI. May not be needed with full install.
  #curl -fsSL https://lmstudio.ai/download/latest/linux/x64?format=deb
  curl -fsSL https://hermes-agent-nousresearch.com/install.sh | bash #<--Convert to wget
  #hermes setup #
}

main(){
  check-for-admin
  #system-update
  download-dependancies
  validateFileChecksums
  #install-ai-dependancies
}

main
