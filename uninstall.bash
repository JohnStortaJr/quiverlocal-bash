#!/usr/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

QUIVER_ROOT=`dirname "$(realpath $0)"`
source $QUIVER_ROOT/core-func.bash

# Run a sudo command to capture the password as soon as the script is run
sudo echo "${bold}QuiverLocal WordPress Development Environment Tool${normal} (uninstall)"

# Define key variables
initializeVariables

# Collect site details
echo ""
getSiteName
getDomainName
getDatabaseName

echo ""
echo "###########################"
echo "## Configuration Details ##"
echo "###########################"
echo "${bold}Domain Core Configuration File:${normal} $DOMAIN_CONFIG/$SITE_NAME.core"
echo "${bold}Apache Site Configuration File:${normal} $APACHE_CONF/$SITE_NAME.conf"
echo ""
echo "${bold}Website Name:${normal} $SITE_NAME"
echo "${bold}Domain Name:${normal} $DOMAIN_NAME"
echo "${bold}WordPress Site Directory:${normal} $DOMAIN_HOME/$DOMAIN_NAME"
echo ""
echo "${bold}Database Name:${normal} $DB_NAME"

CONFIRMATION_COUNT=0
# Confirm that the user wishes to proceed given the provided configuration details
read -p "Do you wish to delete the above configuration? [y:N]: " userGoNoGo
goNoGo="${userGoNoGo:='n'}"

# Abort the deletion unless the user explicitly enters 'y' or 'Y'
if [ $goNoGo = "y" ] || [ $goNoGo = "Y" ]; then
    CONFIRMATION_COUNT=$((CONFIRMATION_COUNT+1))
    read -p "${bold}Are you sure (there is no turning back)?${normal} [y:N]: " userGoNoGo
    goNoGo="${userGoNoGo:='n'}"

    if [ $goNoGo = "y" ] || [ $goNoGo = "Y" ]; then
        CONFIRMATION_COUNT=$((CONFIRMATION_COUNT+1))
    fi
fi

# There must be 2 removal confirmations before proceeding
if [ $CONFIRMATION_COUNT -gt 1 ]; then
    echo "Removing $SITE_NAME"
    uninstallSite
else
    echo "Aborting site removal!"
fi
