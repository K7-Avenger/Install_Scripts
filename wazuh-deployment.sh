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
check_for_admin(){
  if [[ "$EUID" -ne 0 ]]; then
    echo -e -n "${RED}"
    echo "This script must be run as root. Use sudo or switch to the root user."
    echo -e -n "${RESET}"
    exit 1
  fi
}

#The purpose of this function is to update the underlying host system and
#download any dependancies required for installation
perform_system_updates(){
  apt-get update && apt-get upgrade -y
  apt-get install curl -y
  apt autoremove -y
}

#The purpose of this function is to download the Wazuh isntallation script from
#official source and run the installer.
download_and_run_installer(){
  echo "Downloading and running Wazuh installer"
  curl -sO https://packages.wazuh.com/4.13/wazuh-install.sh && sudo bash ./wazuh-install.sh -a
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
diable_wazuh_updates(){
  echo "Per Wazuh documentation, disabling Wazuh-specific updates"
  echo "For more information see https://documentation.wazuh.com/current/quickstart.html"
  sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list
  apt update
}

get_network_cidr(){
    # Get "IP/Prefix" of default interface
    iface=$(ip route show default | awk '/default/ {print $5}')
    ipcidr=$(ip -o -4 addr show "$iface" | awk '{print $4}')
    ip=${ipcidr%/*}
    prefix=${ipcidr#*/}

    # Convert IP to integer
    IFS=. read -r o1 o2 o3 o4 <<< "$ip"
    ipint=$(( (o1 << 24) + (o2 << 16) + (o3 << 8) + o4 ))

    # Build netmask from prefix length
    mask=$(( 0xFFFFFFFF << (32 - prefix) & 0xFFFFFFFF ))

    # Network address = IP & netmask
    net=$(( ipint & mask ))

    # Convert back to dotted-decimal and print CIDR
    printf "%d.%d.%d.%d/%s\n" \
        $(( (net >> 24) & 255 )) \
        $(( (net >> 16) & 255 )) \
        $(( (net >> 8) & 255 )) \
        $(( net & 255 )) \
        "$prefix"
}

#The purpose of this function is to modify the default configuration to
#allow Wazuh to receive syslog events from non-Wazuh-agent sources. This
#will enable Wazuh to collect syslog events froum sources not capable of
#running an agent such as routers/switches/firewalls, etc. 
# Enable syslog collection from non-agent sources (idempotent, supports repeated -e calls)
enable_syslog_receiver(){
  echo "Enabling collection of syslog events from non-agent sources..."
  CONF_FILE="/var/ossec/etc/ossec.conf"
  BACKUP_FILE="/var/ossec/etc/ossec.conf.bak.$(date +%Y%m%d-%H%M%S)"
  WAZUH_MANAGER_IP="127.0.0.1"

  # Always include host's network CIDR
  CIDR_IP=$(get_network_cidr)

  # Combine host CIDR with any user-supplied extra CIDRs
  NEW_IPS=("$CIDR_IP" "$@")

  if [[ ! -f "$CONF_FILE" ]]; then
    echo "Wazuh config $CONF_FILE not found; aborting."
    return 1
  fi

  # Always make a timestamped backup
  cp "$CONF_FILE" "$BACKUP_FILE" || { echo "Backup failed"; return 1; }
  echo "Backup saved to $BACKUP_FILE"

  if grep -q "<connection>syslog</connection>" "$CONF_FILE"; then
    echo "Syslog <remote> block already exists — merging allowed-ips entries."

    # Extract existing IPs between <allowed-ips> ... </allowed-ips>
    EXISTING_IPS=$(awk '/<allowed-ips>/{flag=1;next}/<\/allowed-ips>/{flag=0}flag' "$CONF_FILE")
    MERGED_IPS=($EXISTING_IPS)

    for ip in "${NEW_IPS[@]}"; do
      if [[ ! " ${MERGED_IPS[*]} " =~ " ${ip} " ]]; then
        MERGED_IPS+=("$ip")
        echo "Added new allowed-ips: $ip"
      else
        echo "allowed-ips $ip already present, skipping."
      fi
    done

    # Rebuild the <allowed-ips> block
    ALLOWED_BLOCK="  <allowed-ips>\n"
    for ip in "${MERGED_IPS[@]}"; do
      ALLOWED_BLOCK+="    ${ip}\n"
    done
    ALLOWED_BLOCK+="  </allowed-ips>"

    # Replace the old block with the new one
    awk -v block="$ALLOWED_BLOCK" '
      BEGIN{inblock=0}
      /<allowed-ips>/{inblock=1;print block;next}
      /<\/allowed-ips>/{inblock=0;next}
      !inblock{print}
    ' "$CONF_FILE" > "${CONF_FILE}.tmp" && mv "${CONF_FILE}.tmp" "$CONF_FILE"

  else
    echo "No syslog <remote> block found — creating one with provided IPs."
    ALLOWED_BLOCK="  <allowed-ips>\n"
    for ip in "${NEW_IPS[@]}"; do
      ALLOWED_BLOCK+="    ${ip}\n"
    done
    ALLOWED_BLOCK+="  </allowed-ips>"

    sed -i "/<\/ossec_config>/i \\<remote>\\n  <connection>syslog</connection>\\n  <port>514</port>\\n  <protocol>tcp</protocol>\\n${ALLOWED_BLOCK}\\n  <local_ip>${WAZUH_MANAGER_IP}</local_ip>\\n</remote>\\n" "$CONF_FILE"
  fi

  echo "Current syslog <remote> block:"
  awk '/<remote>/{flag=1} flag{print} /<\/remote>/{flag=0}' "$CONF_FILE"

  systemctl restart wazuh-manager
  systemctl status --no-pager wazuh-manager
}



check_for_admin
while getopts 'idea :' OPTION; do
	case "$OPTION" in
		i)
			perform_system_updates
			download_and_run_installer
			;;
		d)
			diable_wazuh_updates
			;;
		e)
			enable_syslog_receiver
			;;
		a)
			download_and_run_installer
			diable_wazuh_updates
			enable_syslog_receiver
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
