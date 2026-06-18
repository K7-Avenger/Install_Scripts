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

INSTALL_DIR="/immich-app"

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

install-dependancies(){
  sudo apt install curl -y
  curl -fsSL https://lmstudio.ai/install.sh | bash
  curl -fsSL https://hermes-agent-nousresearch.com/install.sh | bash
  #hermes setup #
}

main(){
  check-for-admin
  system-update
  install-ai-dependancies
}

main
