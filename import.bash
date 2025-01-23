#!/usr/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

QUIVER_ROOT=`dirname "$(realpath $0)"`
source $QUIVER_ROOT/core-func.bash

# Run a sudo command to capture the password as soon as the script is run
sudo echo "${bold}QuiverLocal WordPress Development Environment Tool${normal} (import)"

# Define key variables
initializeVariables

# Collect site details
echo ""
getSiteName
getDomainName
getServerAdmin
getDatabaseName
getDatabaseUser
getDatabasePassword
getImportFile
getImportData

echo ""
echo "###########################"
echo "## Configuration Details ##"
echo "###########################"
echo "${bold}User Home Directory:${normal} $USER_HOME"
echo "${bold}QuiverLocal Home directory:${normal} $QUIVER_ROOT"
echo "${bold}Certificates Directory:${normal} $CERT_HOME"
echo "${bold}Exports Directory:${normal} $EXPORT_HOME"
echo "${bold}Domains Directory:${normal} $DOMAIN_HOME"
echo ""
echo "${bold}Domain Core Configuration File:${normal} $DOMAIN_CONFIG/$SITE_NAME.core"
echo "${bold}Apache Site Configuration File:${normal} $APACHE_CONF/$SITE_NAME.conf"
echo "${bold}Apache Log Directory:${normal} $APACHE_LOG"
echo ""
echo "${bold}Website Name:${normal} $SITE_NAME"
echo "${bold}Domain Name:${normal} $DOMAIN_NAME"
echo "${bold}Server Admin:${normal} $SERVER_ADMIN"
echo "${bold}WordPress Site Directory:${normal} $DOMAIN_HOME/$DOMAIN_NAME"
echo "${bold}WordPress Configuration File:${normal} $DOMAIN_HOME/$DOMAIN_NAME/wp-config.php"
echo ""
echo "${bold}Database Name:${normal} $DB_NAME"
echo "${bold}Database User:${normal} $DB_USER"
echo "${bold}Database Password:${normal} $DB_PASS"

echo "${bold}Import File:${normal} $IMPORT_FILE"
echo "${bold}Import Data:${normal} $IMPORT_DATA"

# Confirm that the user wishes to proceed given the provided configuration details
read -p "Please verify the above configuration. Do you wish to proceed? [y:N]: " userGoNoGo
goNoGo="${userGoNoGo:='n'}"

# Abort the installation unless the user explicitly enters 'y' or 'Y'
if [ $goNoGo != "y" ] && [ $goNoGo != "Y" ]; then
    echo "Aborting import!"
    exit 0;
fi

# Configuration accepted. Proceed with the import.
installRequiredPackages
importFiles
changeApacheUser
createCoreDomainConfig
createApacheConfig
createEmptyDatabase
importData
updateWordPressConfig
updateWordPressURLs
restartApache