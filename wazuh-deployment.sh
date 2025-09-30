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

#The purpose of this function is to check if the script is being executed with
#root/admin permissions. This is required for certian aspects of the script.
check-for-admin(){
  if [[ "$EUID" -ne 0 ]]; then
    echo -e -n "${RED}"
    echo "This script must be run as root. Use sudo or switch to the root user."
    echo -e -n "${RESET}"
    exit 1
  fi
}

#The purpose of this function is to update the underlying host system and
#download any dependancies required for installation
perform-system-updates(){
  sudo apt-get update && apt-get upgrade -y
  sudo apt-get install curl -y
  sudo apt autoremove -y
}

#The purpose of this function is to download the Wazuh isntallation script from
#official source and run the installer.
download-and-run-installer(){
  echo "Downloading and running Wazuh installer"
  sudo curl -sO https://packages.wazuh.com/4.13/wazuh-install.sh && sudo bash ./wazuh-install.sh -a
  echo -e -n "${GREEN}"
  echo "RECORD LOGIN CREDENTIALS LISTED ABOVE TO ACCESS THE DASHBOARD"
  echo -e -n "${GREEN}"
  echo -n "Login at https://$(hostname -I | cut -d ' ' -f1):443 with the provided credentials"
  echo -e "${RESET}"
}

#The purpose of this function is to disable Wazuh updates as the updates may 
#break the environment. While this is a recomended action by Wazuh, users
#are encouraged to follow best practices and any applicable rules, regulations,
#and/or organizational policies.
diable-wazuh-updates(){
  echo "Per Wazuh documentation, disabling Wazuh-specific updates"
  echo "For more information see https://documentation.wazuh.com/current/quickstart.html"
  sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list
  apt update
}

get_network_cidr(){
    # Get "IP/Prefix" of default interface
    ipcidr=$(ip -o -4 addr show "$(ip route show default | awk '/default/ {print $5}')" | awk '{print $4}')
    ip=${ipcidr%/*}
    prefix=${ipcidr#*/}

    # Convert IP to integer
    IFS=. read -r o1 o2 o3 o4 <<< "$ip"
    ipint=$(( (o1 << 24) + (o2 << 16) + (o3 << 8) + o4 ))

    # Build netmask from prefix length
    mask=$(( 0xFFFFFFFF << (32 - prefix) & 0xFFFFFFFF ))

    # Network address = IP & netmask
    net=$(( ipint & mask ))

    # Convert back to dotted-decimal
    CIDR=$(printf "%d.%d.%d.%d/%s\n" \
        $(( (net >> 24) & 255 )) \
        $(( (net >> 16) & 255 )) \
        $(( (net >> 8) & 255 )) \
        $(( net & 255 )) \
        "$prefix")
		
	return $CIDR
}

#The purpose of this function is to modify the default configuration to
#allow Wazuh to receive syslog events from non-Wazuh-agent sources. This
#will enable Wazuh to collect syslog events froum sources not capable of
#running an agent such as routers/switches/firewalls, etc. 
enable-syslog-reciever(){		#Needs testing/further refinement
  echo "Enabling collection of syslog events from non-agent sources..."
  CONF_FILE="/var/ossec/etc/ossec.conf"
  BACKUP_FILE="/var/ossec/etc/ossec.conf.bak.$(date +%F-%H%M%S)"
  WAZUH_MANAGER_IP="127.0.0.1"

  CIDR_IP=get_network_cidr

  sudo cp "$CONF_FILE" "$BACKUP_FILE" || { echo "Backup failed"; return 1; }
  echo "Backup saved to $BACKUP_FILE"

  sudo sed -i "/<\/ossec_config>/i \  <remote>\n    <connection>syslog</connection>\n    <port>514</port>\n    <protocol>tcp</protocol>\n    <allowed-ips>${CIDR_IP}</allowed-ips>\n    <local_ip>${WAZUH_MANAGER_IP}</local_ip>\n  </remote>\n" "$CONF_FILE"
  echo "New <remote> block added with allowed-ips=${CIDR_IP}"

  echo "🔍 Verifying inserted block:"
  awk '/<remote>/{flag=1} flag{print} /<\/remote>/{flag=0}' "$CONF_FILE" | tail -n6

  systemctl restart wazuh-manager
  systemctl status wazuh-manager
}


check-for-admin
while getopts 'idea :' OPTION; do
	case "$OPTION" in
		i)
			perform-system-updates
			download-and-run-installer
			;;
		d)
			diable-wazuh-updates
			;;
		e)
			enable-syslog-reciever
			;;
		a)
			download-and-run-installer
			diable-wazuh-updates
			enable-syslog-reciever
			;;
		?)
			echo -e "Correct usage:\t $(basename $0) -flag(s)"
			echo -e "-i\t Downloads and runs the Wazuh installation script"
			echo -e "-d\t Disables Wazuh-specific updates."
			echo -e "-e\t Enables collection of syslog events from non-agent sources"
			echo -e "-a\t Performs all steps, (download, disable updates, enable syslog collection)."
			exit
			;;
	esac
done
