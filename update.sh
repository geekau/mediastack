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

# This checks for missing variables and invalid docker compose configuration
echo
echo Validating Docker Compose configuration...
echo
if ! docker compose config > /dev/null; then
    echo
    echo Docker Compose configuration is invalid or missing required variables...
    echo
    exit 1
fi

# Download all Docker images - will also pull newer / updated images if they exist
echo
echo Pulling new / updated Docker images...
echo
sudo docker compose pull

# normal pull completes, continue to prune prompt

echo
echo Press:
echo    - \"y\" to purge all old / non-persistent Docker containers, volumes, and networks
echo    - any other key to finish update...
echo
echo Note: If docker is not running, all images will be deleted, and need downloading again - this may take time.
echo
read -n 1 -s -r -p "Your choice: " USER_CHOICE
echo
if [[ "$USER_CHOICE" != "y" ]]; then
    echo
    echo "✅ Update complete! No containers, volumes, or networks were purged"
    echo
    echo "Note: Containers need to be recreated using restart.sh script, before new images take effect"
    echo
    exit 0
fi

sudo docker image      prune -a -f   # Force-remove all Docker images
sudo docker container  prune -f      # Force-remove all Docker containers
sudo docker volume     prune -f      # Force-remove all non-persistent Docker volumes
sudo docker network    prune -f      # Force-remove all Docker networks
echo
echo "✅ Update complete! All old / non-persistent containers, volumes, and networks have been purged."
echo
echo "Note: Containers need to be recreated using restart.sh script, before new images take effect"
echo 
