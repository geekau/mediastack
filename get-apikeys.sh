#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Check if .env exists beside this script
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $SCRIPT_DIR/"
    exit 1
fi

# Read values from .env and clean them
get_env_value() {
    local VAR_NAME="$1"
    grep -E "^${VAR_NAME}=" "$ENV_FILE" | cut -d '=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*#.*//' | tr -d '\r' | tail -n 1
}

FOLDER_FOR_CONFIG=$(get_env_value "FOLDER_FOR_CONFIG")
FOLDER_FOR_MEDIA=$(get_env_value "FOLDER_FOR_MEDIA")
FOLDER_FOR_DATA=$(get_env_value "FOLDER_FOR_DATA")
PUID=$(get_env_value "PUID")
PGID=$(get_env_value "PGID")

# Validate required vars
MISSING_VARS=()
[ -z "$FOLDER_FOR_CONFIG" ] && MISSING_VARS+=("FOLDER_FOR_CONFIG")
[ -z "$FOLDER_FOR_MEDIA" ]  && MISSING_VARS+=("FOLDER_FOR_MEDIA")
[ -z "$FOLDER_FOR_DATA" ]   && MISSING_VARS+=("FOLDER_FOR_DATA")
[ -z "$PUID" ]              && MISSING_VARS+=("PUID")
[ -z "$PGID" ]              && MISSING_VARS+=("PGID")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: The following required variables are missing or empty in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

echo
echo "✅ Found the following variables / values:"
echo "   - FOLDER_FOR_CONFIG=$FOLDER_FOR_CONFIG"
echo "   - FOLDER_FOR_MEDIA=$FOLDER_FOR_MEDIA"
echo "   - FOLDER_FOR_DATA=$FOLDER_FOR_DATA"
echo "   - PUID=$PUID"
echo "   - PGID=$PGID"

echo 
echo Extracting all current API Keys...
echo 

echo "Bazarr  - - - - API Key: " `yq -r '.auth.apikey' $FOLDER_FOR_DATA/bazarr/config/config.yaml`                   "  located in $FOLDER_FOR_DATA/bazarr/config/config.yaml"
echo "LazyLibrarian - API Key: " `grep '^api_key' $FOLDER_FOR_DATA/lazylibrarian/config.ini | sed -E 's/.*=\s*//'`   "  located in $FOLDER_FOR_DATA/lazylibrarian/config.ini"
echo "Lidarr  - - - - API Key: " `xmllint --xpath "string(//Config/ApiKey)" $FOLDER_FOR_DATA/lidarr/config.xml`      "  located in $FOLDER_FOR_DATA/lidarr/config.xml"
echo "Mylar - - - - - API Key: " `grep '^api_key' $FOLDER_FOR_DATA/mylar/mylar/config.ini | sed -E 's/.*=\s*//'`     "  located in $FOLDER_FOR_DATA/mylar/mylar/config.ini"
echo "Prowlarr  - - - API Key: " `xmllint --xpath "string(//Config/ApiKey)" $FOLDER_FOR_DATA/prowlarr/config.xml`    "  located in $FOLDER_FOR_DATA/prowlarr/config.xml"
echo "Radarr  - - - - API Key: " `xmllint --xpath "string(//Config/ApiKey)" $FOLDER_FOR_DATA/radarr/config.xml`      "  located in $FOLDER_FOR_DATA/radarr/config.xml"
echo "Sonarr  - - - - API Key: " `xmllint --xpath "string(//Config/ApiKey)" $FOLDER_FOR_DATA/sonarr/config.xml`      "  located in $FOLDER_FOR_DATA/sonarr/config.xml"
echo "Whisparr  - - - API Key: " `xmllint --xpath "string(//Config/ApiKey)" $FOLDER_FOR_DATA/whisparr/config.xml`    "  located in $FOLDER_FOR_DATA/whisparr/config.xml"
echo 
