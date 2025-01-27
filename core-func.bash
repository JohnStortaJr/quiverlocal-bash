#!/usr/bin/bash

function determineHostOS() {
    ISFEDORA=`cat /etc/*release | grep -ci fedora`
    ISDEBIAN=`cat /etc/*release | grep -ci debian`
    ISUBUNTU=`cat /etc/*release | grep -ci ubuntu`
    
    if [ ${ISFEDORA} -gt 0 ]; then
        HOST_OS="Fedora"
    elif [ ${ISUBUNTU} -gt 0 ]; then
        HOST_OS="Ubuntu"
    elif [ ${ISDEBIAN} -gt 0 ]; then
        HOST_OS="Debian"
    fi

    if [ ${HOST_OS} == "Unknown" ]; then
        echo "ERROR: Could not determine host Operating System"
        echo "Quiverlocal is tested to work with Fedora and Debian"
        echo "Exiting"
        return 1
    else 
        echo "Running Quiverlocal for ${HOST_OS}..."
        echo ""
    fi
}

function initializeVariables() {
    USER=`whoami`
    USER_HOME=/home/$USER

    CERT_HOME=$QUIVER_DB/certificates
    IMPORT_FILE=$QUIVER_DB/imports/NOFILE
    IMPORT_DATA=$QUIVER_DB/imports/NODATA

    if [ ${HOST_OS} == "Fedora" ]; then
        APACHE_ROOT=/etc/httpd
        APACHE_CONF=$APACHE_ROOT/conf.d
        APACHE_LOG=/var/log/httpd

        DOMAIN_HOME=/var/www/html
        DOMAIN_CONFIG=$APACHE_CONF
    else
        APACHE_ROOT=/etc/apache2
        APACHE_CONF=$APACHE_ROOT/sites-available
        APACHE_LOG=/var/log/apache2

        DOMAIN_HOME=$USER_HOME/domains
        DOMAIN_CONFIG=$DOMAIN_HOME/config
    fi

    SITE_NAME="dev1.sitename"
    DOMAIN_NAME="${SITE_NAME}.local"
    SERVER_ADMIN="name@domain.local"

    DB_NAME="${SITE_NAME}_db"
    DB_USER=wordpress
    DB_PASS=start123

    CERT_NAME="myCert"
    CERT_DUR=365
    CERT_KEY_FILE=$CERT_HOME/localcert.key
    CERT_FILE=$CERT_HOME/localcert.crt
}

# Get User Inputs
function getSiteName() {
    read -p "${bold}Site Name ${normal}[localdev01]: " userin_SITE_NAME
    SITE_NAME="${userin_SITE_NAME:=$SITE_NAME}"
    SITE_NAME="`echo ${SITE_NAME} | sed 's|\\/|_|g'`"
    SITE_NAME="`echo ${SITE_NAME} | sed 's|\\\|_|g'`"

    DOMAIN_NAME=$SITE_NAME.local

    DB_NAME="`echo ${SITE_NAME} | sed 's|\.|_|g'`_db"
}


function getDomainName() {
    read -p "${bold}Domain Name ${normal}[$DOMAIN_NAME]: " userin_DOMAIN_NAME
    DOMAIN_NAME="${userin_DOMAIN_NAME:=$DOMAIN_NAME}"

    DOMAIN_NAME="`echo ${DOMAIN_NAME} | sed 's|\\/|_|g'`"
    DOMAIN_NAME="`echo ${DOMAIN_NAME} | sed 's|\\\|_|g'`"
}

function getServerAdmin() {
    read -p "${bold}Server Admin ${normal}[$SERVER_ADMIN]: " userin_SERVER_ADMIN
    SERVER_ADMIN="${userin_SERVER_ADMIN:=$SERVER_ADMIN}"

    SERVER_ADMIN="`echo ${SERVER_ADMIN} | sed 's|\\/|_|g'`"
    SERVER_ADMIN="`echo ${SERVER_ADMIN} | sed 's|\\\|_|g'`"
}

function getDatabaseName() {
    read -p "${bold}Database Name ${normal}[$DB_NAME]: " userin_DB_NAME
    DB_NAME="${userin_DB_NAME:=$DB_NAME}"
    DB_NAME="`echo ${DB_NAME} | sed 's|\\/|_|g'`"
    DB_NAME="`echo ${DB_NAME} | sed 's|\\\|_|g'`"
    DB_NAME="`echo ${DB_NAME} | sed 's|\.|_|g'`"
}

function getDatabaseUser() {
    read -p "${bold}Database Username ${normal}[$DB_USER]: " userin_DB_USER
    DB_USER="${userin_DB_USER:=$DB_USER}"
}

function getDatabasePassword() {
    read -p "${bold}Database Password ${normal}[$DB_PASS]: " userin_DB_PASS
    DB_PASS="${userin_DB_PASS:=$DB_PASS}"
}

function getImportFile() {
    read -p "${bold}Import File ${normal}[$IMPORT_FILE]: " userin_IMPORT_FILE
    IMPORT_FILE="${userin_IMPORT_FILE:=$IMPORT_FILE}"
}

function getImportData() {
    read -p "${bold}Database File ${normal}[$IMPORT_DATA]: " userin_IMPORT_DATA
    IMPORT_DATA="${userin_IMPORT_DATA:=$IMPORT_DATA}"
    SQL_FILE=`echo ${IMPORT_DATA} | sed 's|\.gz||g'`
}

function getCertificatePath() {
    read -p "${bold}Certificate Path ${normal}[$CERT_HOME]: " userin_CERT_HOME
    CERT_HOME="${userin_CERT_HOME:=$CERT_HOME}"
}

function getCertificateName() {
    read -p "${bold}Certificate Name ${normal}[$CERT_NAME]: " userin_CERT_NAME
    CERT_NAME="${userin_CERT_NAME:=$CERT_NAME}"
}

function getCertificateDuration() {
    read -p "${bold}Certificate Duration ${normal}[$CERT_DUR]: " userin_CERT_DUR
    CERT_DUR="${userin_CERT_DUR:=$CERT_DUR}"
}

function getCertificate() {
    read -p "${bold}Certificate File (.crt)${normal}[$CERT_FILE]: " userin_CERT_FILE
    CERT_FILE="${userin_CERT_FILE:=$CERT_FILE}"

    read -p "${bold}Certificate Key File (.key)${normal}[$CERT_KEY_FILE]: " userin_CERT_KEY_FILE
    CERT_KEY_FILE="${userin_CERT_KEY_FILE:=$CERT_KEY_FILE}"
}

function createRootCertificate() {
    echo " "
    echo "${bold}Creating ROOT Certificate Private Key${normal} ${CERT_HOME}/${CERT_NAME}.key"
    openssl genrsa -aes256 -out "${CERT_HOME}/${CERT_NAME}.key" 2048

    echo " "
    echo "${bold}Creating ROOT Certificate${normal} ${CERT_HOME}/${CERT_NAME}.pem"
    openssl req -x509 -new -noenc -key "${CERT_HOME}/${CERT_NAME}.key" -sha256 -days $CERT_DUR -out "${CERT_HOME}/${CERT_NAME}.pem"
}

#Download the latest wordpress files, unpack them into the $DOMAIN_HOME, and rename the directory
function installLatestWordpress() {
    cd $DOMAIN_HOME
    sudo curl https://wordpress.org/latest.tar.gz | sudo tar zx -C $DOMAIN_HOME
    sudo mv $DOMAIN_HOME/wordpress $DOMAIN_HOME/$DOMAIN_NAME
    sudo chown -R apache:apache $DOMAIN_HOME/$DOMAIN_NAME
}


# Setup Apache to run as the current user
function changeApacheUser() {
    cp $APACHE_ROOT/envvars $QUIVER_ROOT/tmp/tenvars.bak
    cp $APACHE_ROOT/envvars $QUIVER_ROOT/tmp/tenvars
    sed -i "s/APACHE_RUN_USER=www-data/APACHE_RUN_USER=$USER/g" $QUIVER_ROOT/tmp/tenvars
    sed -i "s/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=$USER/g" $QUIVER_ROOT/tmp/tenvars
    sudo mv $QUIVER_ROOT/tmp/tenvars $APACHE_ROOT/envvars
    sudo chown root: $APACHE_ROOT/envvars
}


# Setup the core configuration for the domain
function createCoreDomainConfig() {
    if [ ! -d $DOMAIN_CONFIG ]; then
        mkdir $DOMAIN_CONFIG
    fi

    sed "s|__SERVERADMIN__|$SERVER_ADMIN|g" $QUIVER_ROOT/base/default.core > $QUIVER_ROOT/tmp/tcoreconf
    sed -i "s|__DOMAINNAME__|$DOMAIN_NAME|g" $QUIVER_ROOT/tmp/tcoreconf
    sed -i "s|__DOMAINDIR__|$DOMAIN_HOME/$DOMAIN_NAME|g" $QUIVER_ROOT/tmp/tcoreconf

    sudo cp $QUIVER_ROOT/tmp/tcoreconf $DOMAIN_CONFIG/$SITE_NAME.core
}

# setup the Apache configuration file for this domain
function createApacheConfig() {

    echo "Updating Apache Configuration"
    echo $DOMAIN_NAME
    cp $QUIVER_ROOT/base/default_http.conf $QUIVER_ROOT/tmp/thttpconf
    cp $QUIVER_ROOT/base/default_http.conf $QUIVER_ROOT/tmp/thttpconf.bak
    sed -i "s|__CORECONFIG__|$DOMAIN_CONFIG/$SITE_NAME.core|g" $QUIVER_ROOT/tmp/thttpconf
    sudo mv $QUIVER_ROOT/tmp/thttpconf $APACHE_CONF/$SITE_NAME.conf
    sudo chown root: $APACHE_CONF/$SITE_NAME.conf

    if [ ${HOST_OS} != "Fedora" ]; then
        # Enable the site
        sudo a2ensite $SITE_NAME

        # Disable the default site
        sudo a2dissite 000-default

        # Enable the mod_rewrite module
        sudo a2enmod rewrite
    fi
}

function trustSite() {
    # Should check to make sure there is not already a 443 block in the file
    cp $APACHE_CONF/$SITE_NAME.conf $QUIVER_ROOT/tmp/thttpsconf

    cat $QUIVER_ROOT/base/default_https.conf >> $QUIVER_ROOT/tmp/thttpsconf

    sed -i "s|__CORECONFIG__|$DOMAIN_CONFIG/$SITE_NAME.core|g" $QUIVER_ROOT/tmp/thttpsconf
    sed -i "s|__CERTFILE__|$CERT_FILE|g" $QUIVER_ROOT/tmp/thttpsconf
    sed -i "s|__CERTKEYFILE__|$CERT_KEY_FILE|g" $QUIVER_ROOT/tmp/thttpsconf

    sudo mv $QUIVER_ROOT/tmp/thttpsconf $APACHE_CONF/$SITE_NAME.conf
    sudo chown root: $APACHE_CONF/$SITE_NAME.conf

    # Enable the mod_ssl module
    sudo a2enmod ssl

    # Update the siteurl and home values in the database
    # Get the table prefix
    TABLE_PREFIX=`grep table_prefix ${DOMAIN_HOME}/${DOMAIN_NAME}/wp-config.php | sed -n "s/^.*'\(.*\)'.*$/\1/ p"`
    echo $TABLE_PREFIX

    # Update siteurl and home values
    SITE_QUERY="UPDATE ${TABLE_PREFIX}options SET option_value = 'https://${DOMAIN_NAME}' WHERE ${TABLE_PREFIX}options.option_name = 'siteurl'"
    HOME_QUERY="UPDATE ${TABLE_PREFIX}options SET option_value = 'https://${DOMAIN_NAME}' WHERE ${TABLE_PREFIX}options.option_name = 'home'"

    sudo mysql -u root $DB_NAME -e "${SITE_QUERY}"
    sudo mysql -u root $DB_NAME -e "${HOME_QUERY}"
}


### Setup empty database
function createEmptyDatabase() {
    cp $QUIVER_ROOT/base/default_dbsetup.sql $QUIVER_ROOT/tmp/tdbconf
    sed -i "s|__DBNAME__|$DB_NAME|g" $QUIVER_ROOT/tmp/tdbconf
    sed -i "s|__DBUSER__|$DB_USER|g" $QUIVER_ROOT/tmp/tdbconf
    sed -i "s|__DBPASS__|$DB_PASS|g" $QUIVER_ROOT/tmp/tdbconf

    sudo mysql -u root < $QUIVER_ROOT/tmp/tdbconf
}


### Setup wordpress config
function createWordPressConfig() {
    cp $DOMAIN_HOME/$DOMAIN_NAME/wp-config-sample.php $QUIVER_ROOT/tmp/twpconf
    sed -i "s|database_name_here|$DB_NAME|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|username_here|$DB_USER|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|password_here|$DB_PASS|g" $QUIVER_ROOT/tmp/twpconf

    echo "Updating SALTs"
    NEW_AUTH_KEY="define( 'AUTH_KEY',         '`openssl rand -base64 48`' );"
    NEW_SECURE_AUTH_KEY="define( 'SECURE_AUTH_KEY',  '`openssl rand -base64 48`' );"
    NEW_LOGGED_IN_KEY="define( 'LOGGED_IN_KEY',    '`openssl rand -base64 48`' );"
    NEW_NONCE_KEY="define( 'NONCE_KEY',        '`openssl rand -base64 48`' );"
    NEW_AUTH_SALT="define( 'AUTH_SALT',        '`openssl rand -base64 48`' );"
    NEW_SECURE_AUTH_SALT="define( 'SECURE_AUTH_SALT', '`openssl rand -base64 48`' );"
    NEW_LOGGED_IN_SALT="define( 'LOGGED_IN_SALT',   '`openssl rand -base64 48`' );"
    NEW_NONCE_SALT="define( 'NONCE_SALT',       '`openssl rand -base64 48`' );"

    sed -i "s|.*'AUTH_KEY.*|$NEW_AUTH_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'SECURE_AUTH_KEY.*|$NEW_SECURE_AUTH_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'LOGGED_IN_KEY.*|$NEW_LOGGED_IN_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'NONCE_KEY.*|$NEW_NONCE_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'AUTH_SALT.*|$NEW_AUTH_SALT|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'SECURE_AUTH_SALT.*|$NEW_SECURE_AUTH_SALT|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'LOGGED_IN_SALT.*|$NEW_LOGGED_IN_SALT|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'NONCE_SALT.*|$NEW_NONCE_SALT|g" $QUIVER_ROOT/tmp/twpconf

    #ls -al $DOMAIN_HOME/$DOMAIN_NAME/wp-config.php
    sudo cp $QUIVER_ROOT/tmp/twpconf $DOMAIN_HOME/$DOMAIN_NAME/wp-config.php
}

### Update existing WordPress config
function updateWordPressConfig() {
    cp $DOMAIN_HOME/$DOMAIN_NAME/wp-config.php $QUIVER_ROOT/tmp/twpconf

    # Remove cache entry
    sed -i "/WPCACHEHOME/d" $QUIVER_ROOT/tmp/twpconf

    # Replace database connection information with local values
    NEW_DB_NAME_STRING="define( 'DB_NAME', '${DB_NAME}' );"
    NEW_DB_USER_STRING="define( 'DB_USER', '${DB_USER}' );"
    NEW_DB_PASS_STRING="define( 'DB_PASSWORD', '${DB_PASS}' );"
    NEW_DB_HOST_STRING="define( 'DB_HOST', 'localhost' );"
    sed -i "s|.*'DB_NAME'.*|$NEW_DB_NAME_STRING|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'DB_USER'.*|$NEW_DB_USER_STRING|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'DB_PASSWORD'.*|$NEW_DB_PASS_STRING|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'DB_HOST'.*|$NEW_DB_HOST_STRING|g" $QUIVER_ROOT/tmp/twpconf

    echo "Updating SALTs"
    NEW_AUTH_KEY="define( 'AUTH_KEY',         '`openssl rand -base64 48`' );"
    NEW_SECURE_AUTH_KEY="define( 'SECURE_AUTH_KEY',  '`openssl rand -base64 48`' );"
    NEW_LOGGED_IN_KEY="define( 'LOGGED_IN_KEY',    '`openssl rand -base64 48`' );"
    NEW_NONCE_KEY="define( 'NONCE_KEY',        '`openssl rand -base64 48`' );"
    NEW_AUTH_SALT="define( 'AUTH_SALT',        '`openssl rand -base64 48`' );"
    NEW_SECURE_AUTH_SALT="define( 'SECURE_AUTH_SALT', '`openssl rand -base64 48`' );"
    NEW_LOGGED_IN_SALT="define( 'LOGGED_IN_SALT',   '`openssl rand -base64 48`' );"
    NEW_NONCE_SALT="define( 'NONCE_SALT',       '`openssl rand -base64 48`' );"

    sed -i "s|.*'AUTH_KEY.*|$NEW_AUTH_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'SECURE_AUTH_KEY.*|$NEW_SECURE_AUTH_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'LOGGED_IN_KEY.*|$NEW_LOGGED_IN_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'NONCE_KEY.*|$NEW_NONCE_KEY|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'AUTH_SALT.*|$NEW_AUTH_SALT|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'SECURE_AUTH_SALT.*|$NEW_SECURE_AUTH_SALT|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'LOGGED_IN_SALT.*|$NEW_LOGGED_IN_SALT|g" $QUIVER_ROOT/tmp/twpconf
    sed -i "s|.*'NONCE_SALT.*|$NEW_NONCE_SALT|g" $QUIVER_ROOT/tmp/twpconf

    sudo cp $QUIVER_ROOT/tmp/twpconf $DOMAIN_HOME/$DOMAIN_NAME/wp-config.php
    sudo chown -R apache:apache $DOMAIN_HOME/$DOMAIN_NAME
}

function updateWordPressURLs() {
    # Get the table prefix
    TABLE_PREFIX=`grep table_prefix ${DOMAIN_HOME}/${DOMAIN_NAME}/wp-config.php | sed -n "s/^.*'\(.*\)'.*$/\1/ p"`
    echo $TABLE_PREFIX

    # Update siteurl and home values
    SITE_QUERY="UPDATE ${TABLE_PREFIX}options SET option_value = 'http://${DOMAIN_NAME}' WHERE ${TABLE_PREFIX}options.option_name = 'siteurl'"
    HOME_QUERY="UPDATE ${TABLE_PREFIX}options SET option_value = 'http://${DOMAIN_NAME}' WHERE ${TABLE_PREFIX}options.option_name = 'home'"

    sudo mysql -u root $DB_NAME -e "${SITE_QUERY}"
    sudo mysql -u root $DB_NAME -e "${HOME_QUERY}"

    # Should update the WordPress admin password as well, but need to figure out how to identify it
}

function importFiles() {
    cd $DOMAIN_HOME
    tar -xzvf $IMPORT_FILE
    # Need to try and parse the imported path to get the domain so it can be renamed to the desired local values
    IMPORT_ROOT=`tar tzf $IMPORT_FILE | sed -e 's@/.*@@' | uniq`
    mv $DOMAIN_HOME/$IMPORT_ROOT $DOMAIN_HOME/$DOMAIN_NAME
}

function importData() {
    echo "Importing Data"
    # No idea how to import the data from the command line. For now this can be imported easily enough through phpMyAdmin
    gzip -d $IMPORT_DATA
    sudo mysql -u root $DB_NAME < $SQL_FILE
}

# Restart Apache
function restartApache() {
    if [ ${HOST_OS} == "Fedora" ]; then
        sudo systemctl restart httpd
    else
        sudo systemctl restart apache2
    fi
}

function uninstallSite() {
    echo "Disabling site $SITE_NAME"
    sudo a2dissite $SITE_NAME

    echo "Removing Apache Site Configuration ($APACHE_CONF/$SITE_NAME.conf)"
    sudo rm -rf $APACHE_CONF/$SITE_NAME.conf

    echo "Removing Domain Core Configuration ($DOMAIN_CONFIG/$SITE_NAME.core)"
    rm -rf $DOMAIN_CONFIG/$SITE_NAME.core

    echo "Removing Domain Directory ($DOMAIN_HOME/$DOMAIN_NAME)"
    rm -rf $DOMAIN_HOME/$DOMAIN_NAME

    echo "Deleting Database ($DB_NAME)"
    sudo mysql -u root -e "DROP DATABASE $DB_NAME"

    restartApache
}
