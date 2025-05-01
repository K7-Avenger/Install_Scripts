#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

downloadFiles(){
	#download the Rapid7 installer
	sudo curl -o /opt/Rapid7Setup-Linux64.bin https://download2.rapid7.com/download/InsightVM/Rapid7Setup-Linux64.bin

	#download the checksum file
	sudo curl -o /opt/Rapid7Setup-Linux64.bin.sha512sum https://download2.rapid7.com/download/InsightVM/Rapid7Setup-Linux64.bin.sha512sum
}

validateFileChecksums(){
	#generate installer checksum
	file_checksum=$(sha512sum /opt/Rapid7Setup-Linux64.bin | cut -d " " -f1)
	echo "file checksum is:\n $file_checksum"

	#read checksum provided by Rapid7
	downloaded_checksum=$(cat /opt/Rapid7Setup-Linux64.bin.sha512sum | cut -d " " -f1)
	echo "provided checksum is:\n $downloaded_checksum"
	
	#compare checksums, abort installation if they do not match
	if [[ $file_checksum == $downloaded_checksum ]]; then
		echo -e -n "${GREEN}"
		echo "sha512sum match! Install may continue, setting (owner) execute bit..."
		echo -e "${RESET}"
		
		#add execute permissions to .bin installer
		sudo chmod 544 /opt/Rapid7Setup-Linux64.bin
	else
		echo -e -n "${RED}"
		echo "sha512sum does not match! Aborting install and removing execute permissions on installer"
		echo -e "${RESET}"
		#remove execute permissions to .bin installer
		sudo chmod -x /opt/Rapid7Setup-Linux64.bin
		exit 1
	fi
}

runInstaller(){
	#generate installer checksum
	file_checksum=$(sha512sum /opt/Rapid7Setup-Linux64.bin | cut -d " " -f1)
	#read checksum provided by Rapid7
	downloaded_checksum=$(cat /opt/Rapid7Setup-Linux64.bin.sha512sum | cut -d " " -f1)
	
	#compare checksums, abort installation if they do not match
	if [[ $file_checksum == $downloaded_checksum ]]; then
		#add execute permissions to .bin installer
		sudo chmod 544 /opt/Rapid7Setup-Linux64.bin
		#run installer
		sudo ./opt/Rapid7Setup-Linux64.bin
	else
		echo -e -n "${RED}"
		echo "sha512sum does not match! Aborting install and removing execute permissions on installer"
		echo -e "${RESET}"
		#remove execute permissions to .bin installer
		sudo chmod -x /opt/Rapid7Setup-Linux64.bin
		exit 1
	fi
	
	
	
}

while getopts 'diva :' OPTION; do
	case "$OPTION" in
		d)
			echo "Downloading required files..."
			downloadFiles
			;;
		i)
			echo "Running Rapid7 installer..."
			runInstaller
			;;
		v)
			echo "Validating checksums..."
			validateFileChecksums
			;;
		a)
			echo "Downloading required files..."
			downloadFiles
			
			echo "Validating checksums..."
			validateFileChecksums
			
			echo "Running Rapid7 installer..."
			runInstaller
			;;
		?)
			echo -e "Correct usage:\t $(basename $0) -flag(s)"
			echo -e "-d\t Downloads the Rapid7 Installer & associated checksum files"
			echo -e "-v\t Verifies the checksum of the installer."
			echo -e "-i\t Runs the installer. This option will fail if checksums do not match"
			echo -e "-a\t Performs all steps, (download, verify, install)."
			exit
			;;
	esac
done
