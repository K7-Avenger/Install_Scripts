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


INSTALL_DIR="/opt/ai-testing"
LLM_STUDIO_DEB_SHA="40308930cf9c848cfe0e0c0e353f86a85e54f8ff09c758e0974854f8529d1b6ef5e30bad31a7f8251fedbb2734769e017085144d3ee595889c1e12f6d26e0afe"

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



download-dependancies(){
  mkdir $INSTALL_DIR
  curl -o $INSTALL_DIR/LM-Studio-.0.4.16-2-x64.deb https://lmstudio.ai/download/latest/linux/x64?format=deb

}

validateFileChecksums(){
	#generate installer checksum
	file_checksum=$(sha512sum $INSTALL_DIR/LM-Studio-.0.4.16-2-x64.deb | cut -d " " -f1)
	echo "file checksum is:\n $file_checksum"

	#read checksum provided by Rapid7
	downloaded_checksum=$LLM_STUDIO_DEB_SHA
	echo "provided checksum is:\n $downloaded_checksum"
	
	#compare checksums, abort installation if they do not match
	if [[ $file_checksum == $downloaded_checksum ]]; then
		echo -e -n "${GREEN}"
		echo "sha512sum match! Install may continue, setting (owner) execute bit..."
		echo -e "${RESET}"
		
		#add execute permissions to .bin installer
		sudo chmod 544 $INSTALL_DIR/LM-Studio-.0.4.16-2-x64.deb
	else
		echo -e -n "${RED}"
		echo "sha512sum does not match! Aborting install and removing execute permissions on installer"
		echo -e "${RESET}"
		#remove execute permissions to .bin installer
		sudo chmod -x $INSTALL_DIR/LM-Studio-.0.4.16-2-x64.deb
		exit 1
	fi
}

install-dependancies(){
  sudo apt install curl -y
  #curl -fsSL https://lmstudio.ai/install.sh | bash #<--llmster is LM Studio's headless daemon for servers, cloud instances, and CI.
  curl -fsSL https://lmstudio.ai/download/latest/linux/x64?format=deb
  curl -fsSL https://hermes-agent-nousresearch.com/install.sh | bash
  #hermes setup #
}

main(){
  check-for-admin
  system-update
  install-ai-dependancies
}

main
