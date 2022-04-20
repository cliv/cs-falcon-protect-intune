#!/bin/bash

# Configuration - Add this before uploading - It's a shame that Intune doesn't have secrets support... :(
CLIENT_ID=
CLIENT_SECRET=
CS_CCID=
CS_INSTALL_TOKEN=

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

get_access_token() {
    json=$(curl -s -X POST -d "client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}" https://api.crowdstrike.com/oauth2/token)
    echo "function run() { let result = JSON.parse(\`$json\`); return result.access_token; }" | osascript -l JavaScript
}

get_sha256() {
    json=$(curl -s -H "Authorization: Bearer ${1}" https://api.crowdstrike.com/sensors/combined/installers/v1\?filter=platform%3A%22mac%22)
    echo "function run() { let result = JSON.parse(\`$json\`); return result.resources[0].sha256; }" | osascript -l JavaScript
}

if [ ! -x "/Applications/Falcon.app/Contents/Resources/falconctl" ] || [ -z "$(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep 'Sensor operational: true')" ]; then
    APITOKEN=$(get_access_token)
    FALCON_LATEST_SHA256=$(get_sha256 "${APITOKEN}")
    curl -o /tmp/FalconSensorMacOS.pkg -s -H "Authorization: Bearer ${APITOKEN}" https://api.crowdstrike.com/sensors/entities/download-installer/v1?id=${FALCON_LATEST_SHA256}
    installer -verboseR -package /tmp/FalconSensorMacOS.pkg -target /
    rm /tmp/FalconSensorMacOS.pkg
    /Applications/Falcon.app/Contents/Resources/falconctl license ${CS_CCID} ${CS_INSTALL_TOKEN} || true # Don't fail if the app is already licensed, but still needs a reinstall
else
    echo "Crowdstrike Falcon is installed and operational"
fi
