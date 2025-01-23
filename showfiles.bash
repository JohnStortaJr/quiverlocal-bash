#!/usr/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

QUIVER_ROOT=`dirname "$(realpath $0)"`
source $QUIVER_ROOT/core-func.bash

# Run a sudo command to capture the password as soon as the script is run
sudo echo "${bold}QuiverLocal WordPress Development Environment Tool${normal} (files)"

# Define key variables
initializeVariables

echo ""
echo "${bold}## Certificates: ${normal}$USER_HOME/certificates"
ls -l $USER_HOME/certificates | tail -n +2

echo ""
echo "${bold}## Domains: ${normal}$USER_HOME/domains"
ls -l $USER_HOME/domains | tail -n +2

echo ""
echo "${bold}## Domain Core Configurations: ${normal}$DOMAIN_HOME/config"
ls -l $DOMAIN_HOME/config | tail -n +2

echo ""
echo "${bold}## Apache Site Configurations: ${normal}$APACHE_ROOT/sites-available"
ls -l $APACHE_ROOT/sites-available | tail -n +2

echo ""
echo "${bold}## Enabled Sites: ${normal}$APACHE_ROOT/sites-enabled"
sudo a2query -s | sed "s/(enabled by site administrator)/ /g"
echo ""
echo "${bold}## Databases ##${normal} "
sudo mysql -u root -e "SHOW DATABASES" | tail -n +2