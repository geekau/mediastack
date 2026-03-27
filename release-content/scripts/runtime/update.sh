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

MEDIASTACK_VERSION="$(get_env_value "MEDIASTACK_VERSION" || true)"
GITHUB_REPO="$(get_env_value "GITHUB_REPO" || true)"
FOLDER_FOR_MEDIA=$(get_env_value   "FOLDER_FOR_MEDIA")
FOLDER_FOR_APPDATA=$(get_env_value "FOLDER_FOR_APPDATA")
FOLDER_FOR_RUNTIME=$(get_env_value "FOLDER_FOR_RUNTIME")
PUID=$(get_env_value "PUID")
PGID=$(get_env_value "PGID")

# Validate required vars
MISSING_VARS=()
[ -z "$FOLDER_FOR_MEDIA" ]    && MISSING_VARS+=("FOLDER_FOR_MEDIA")
[ -z "$FOLDER_FOR_APPDATA" ]  && MISSING_VARS+=("FOLDER_FOR_APPDATA")
[ -z "$FOLDER_FOR_RUNTIME" ]  && MISSING_VARS+=("FOLDER_FOR_RUNTIME")
[ -z "$PUID" ]                && MISSING_VARS+=("PUID")
[ -z "$PGID" ]                && MISSING_VARS+=("PGID")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: The following required variables are missing or empty in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

echo
echo "✅ Found the following variables / values:"
echo "   - FOLDER_FOR_MEDIA=$FOLDER_FOR_MEDIA"
echo "   - FOLDER_FOR_APPDATA=$FOLDER_FOR_APPDATA"
echo "   - FOLDER_FOR_RUNTIME=$FOLDER_FOR_RUNTIME"
echo "   - PUID=$PUID"
echo "   - PGID=$PGID"

# This checks for missing variables and invalid docker compose configuration
echo
echo Validating Docker Compose configuration...
echo
if ! sudo docker compose config > /dev/null; then
    echo
    echo Docker Compose configuration is invalid or missing required variables...
    echo
    exit 1
fi

# Routine to check for updated MediaStack release version - can be disabled in .env file
check_for_new_release() {
    local current_version latest_version api_url

    current_version="${MEDIASTACK_VERSION:-}"
    api_url=""

    # Silently skip if version checking is not configured
    [[ -n "$current_version" ]] || return 0
    [[ -n "${GITHUB_REPO:-}" ]] || return 0

    # Silently skip if required tools are unavailable
    command -v curl >/dev/null 2>&1 || return 0

    api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

    latest_version="$(
        curl -fsSL "$api_url" 2>/dev/null \
        | grep -m1 '"tag_name":' \
        | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/' \
        | sed 's/^v//'
    )"

    # Silently skip if GitHub release lookup failed or returned nothing
    [[ -n "$latest_version" ]] || return 0

    echo
    echo "Installed MediaStack version : ${current_version}"
    echo "Latest GitHub release        : ${latest_version}"
    echo

    if [[ "$current_version" == "$latest_version" ]]; then
        echo "MediaStack is already on the latest release."
        echo
        return 0
    fi

    if [[ "$(printf '%s\n%s\n' "$current_version" "$latest_version" | sort -V | tail -n1)" == "$latest_version" ]]; then
        echo "A newer MediaStack release is available."
        echo "Review: https://github.com/${GITHUB_REPO}/releases/latest"
        echo
    fi
}

# Download all Docker images - will also pull newer / updated images if they exist
echo
echo Pulling new / updated Docker images...
echo
sudo docker compose pull

# Check GitHub release status after image pull completes
if [[ -n "$MEDIASTACK_VERSION" && -n "$GITHUB_REPO" ]]; then
    check_for_new_release
fi

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
