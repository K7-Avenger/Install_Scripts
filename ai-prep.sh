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

install-dependancies(){
  sudo apt install curl -y
  curl -fsSL https://lmstudio.ai/install.sh | bash
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
