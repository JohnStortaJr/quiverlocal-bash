#!/usr/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

QUIVER_ROOT=`dirname "$(realpath $0)"`
source $QUIVER_ROOT/core-func.bash

# Run a sudo command to capture the password as soon as the script is run
sudo echo "${bold}QuiverLocal WordPress Development Environment Tool${normal} (trust)"

# Define key variables
initializeVariables

# This script is not used to create certificates, but rather assign existing signed certificates to it
# there should be an option to use an existing certificate or create a new CA ROOT and local certificate

# Collect site details
echo "This script will assign an existing certificate and key to this site."
echo "If you do not yet have a key, then you will need to generate one and ensure it is registered as a CA"

getSiteName
getDomainName
getCertificate
trustSite
restartApache