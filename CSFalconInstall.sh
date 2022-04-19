#!/bin/bash

# Configuration - Add this before uploading - It's a shame that Intune doesn't have secrets support... :(
CLIENT_ID=
CLIENT_SECRET=
CS_CCID=
CS_INSTALL_TOKEN=
BASE_URL=                     # Ex. https://api.crowdstrike.com, https://api.us-2.crowdstrike.com

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

get_access_token() {
    curl -s -X POST -d "client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}" ${BASE_URL}/oauth2/token | \
      grep -o '"access_token": "[^"]*' | grep -o '[^"]*$'
}

get_sha256() {
    curl -s -H "Authorization: Bearer ${1}" ${BASE_URL}/sensors/combined/installers/v1?filter=platform%3A%22mac%22 | \
      grep -o '"sha256": "[^"]*' | grep -o '[^"]*$' | head -1
}

if [ -z "$(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep 'Sensor operational: true')" ]; then
    APITOKEN=$(get_access_token)
    FALCON_LATEST_SHA256=$(get_sha256 ${APITOKEN})
    curl -o /tmp/FalconSensorMacOS.pkg -s -H "Authorization: Bearer ${APITOKEN}" ${BASE_URL}/sensors/entities/download-installer/v1?id=${FALCON_LATEST_SHA256}
    installer -verboseR -package /tmp/FalconSensorMacOS.pkg -target /
    rm /tmp/FalconSensorMacOS.pkg
    /Applications/Falcon.app/Contents/Resources/falconctl license ${CS_CCID} ${CS_INSTALL_TOKEN} || true # Don't fail if the app is already licensed, but still needs a reinstall
else
    echo "Crowdstrike Falcon is installed and operational"
fi
