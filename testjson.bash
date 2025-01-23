#!/usr/bin/bash

QUIVER_ROOT=`dirname "$(realpath $0)"`


function testpython() {
    CHECKDBNAME=`$QUIVER_ROOT/install.py localtest01.json db_name`
    echo $CHECKDBNAME
}


function testjq() {
    FILENAME=localtest01.json

    DOMAIN_NAME=$(jq -r '.domain_name' $FILENAME)
    DB_NAME=$(jq -r '.db_name' $FILENAME)
    DOMAIN_CONF=$(jq -r '.domain_conf' $FILENAME)

    echo "Domain: $DOMAIN_NAME"
    echo "Database: $DB_NAME"
    echo "Config: $DOMAIN_CONF"
    #echo "Names: $names"

    tmp=$(mktemp)
    #jq --arg n $NEWDOMAIN '.domain_name = $n' $FILENAME > $tmp && mv $tmp $FILENAME
    jq --arg n $NEWDOMAIN --arg p $NEWDBNAME '.domain_name = $n | .db_name = $p' $FILENAME > $tmp && mv $tmp $FILENAME

    #jq '.domain_name = "hardcodedvalue"' $FILENAME > "$tmp" && mv "$tmp" $FILENAME

    DOMAIN_NAME=$(jq -r '.domain_name' $FILENAME)
    DB_NAME=$(jq -r '.db_name' $FILENAME)
    DOMAIN_CONF=$(jq -r '.domain_conf' $FILENAME)

    echo "Domain: $DOMAIN_NAME"
    echo "Database: $DB_NAME"
    echo "Config: $DOMAIN_CONF"
}

function getjsonvalues() {
    FILENAME=localtest02.json
    tmp=$(mktemp)
    NEWDOMAIN=localtest07
    NEWDBNAME=localtest07_db
    SITENAME=dev2johnstortajr

    # Get entire JSON for a given sitename
    echo " "
    echo "Get Block"
    jq -r --arg sitename $SITENAME '.[$sitename]' $FILENAME

    # HMMM Read in the entire block and use it to populate variables and such, make changes to it, and then write it out when done. Rather than reading each time.

    # Get a single value from a specific block
    echo " "
    echo "Get Value"
    jq -r --arg sitename $SITENAME '.[$sitename].db_name' $FILENAME

    # Read block into a string and then pull a value from the string
    echo " "
    echo "Get String and read string"
    SITE_JSON=`jq -r --arg sitename $SITENAME '.[$sitename]' $FILENAME`
    JSON_VALUE=$(echo $SITE_JSON | jq -r '.domain_dir')
    echo "${JSON_VALUE}"

    # Edit values in the string
    echo " "
    echo "Edit values in string"
    echo $SITE_JSON | jq --arg n $NEWDOMAIN \
                         --arg p $NEWDBNAME \
                         '.domain_name = $n | .db_name = $p'
    
    
    
    # I have everything to get the JSON data and even make changes to it within the script
    # What I cannot figure out is how to write the changed object back out to the file (overwriting the original values) 
    # or how to create a brand new object and append it to the file. I feel this should be easier as I can have a blank object with all the values and
    # then just update them in the code and write out the full string. But, again, I need to know how to output to the file.
    # I feel this is all trivial in Python but a real PitA in Bash.
    
    
    
    # Update the json file
    echo " "
    echo $SITENAME
    echo $SITE_JSON
    echo $FILENAME
    echo "Output updated file"
    jq --arg sitename $SITENAME \
       --arg newcontent $SITE_JSON \
       '.[$sitename] |= $newcontent' $FILENAME #> $tmp && mv $tmp $FILENAME



    # Get all values for a key (-r returns raw values without quotes)
    #jq -r '.dev2johnstortajr' $FILENAME
    #jq -r --arg sitename $SITENAME '.[$sitename].db_name' $FILENAME
    #jq -r '.' | 'keys' $FILENAME
    #jq -r --arg sn $SITENAME '{.$sn}' $FILENAME
    #jq --arg sn $SITENAME '{.$sn.site_name}' $FILENAME

    # Get all values for a key (-r returns raw values without quotes)
    #jq -r '.[].db_name' $FILENAME
    #jq -r --arg n "dev2.johnstortajr"'.$n.db_name' $FILENAME


    # Update an existing record. The number in the brackets in the element of the overall array where this element is located (2 is the 3rd element)
    #jq --arg n $NEWDOMAIN \
    #   --arg p $NEWDBNAME \
    #   '.[2].domain_name = $n | .[2].db_name = $p' $FILENAME #> $tmp && mv $tmp $FILENAME


    # Create a new site
    #cat $QUIVER_ROOT/localtest01.json | jq '.'
    #jq '. + { "site_name": "newsite", "domain_name": "newdomain" }' $QUIVER_ROOT/localtest01.json > $tmp && mv $tmp newjson

}

#testpython

getjsonvalues