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

FOLDER_FOR_DATA=$(get_env_value "FOLDER_FOR_DATA")
PUID=$(get_env_value "PUID")
PGID=$(get_env_value "PGID")

# Validate required vars
MISSING_VARS=()
[ -z "$FOLDER_FOR_DATA" ] && MISSING_VARS+=("FOLDER_FOR_DATA")
[ -z "$PUID" ]            && MISSING_VARS+=("PUID")
[ -z "$PGID" ]            && MISSING_VARS+=("PGID")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: The following required variables are missing or empty in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

BLUEPRINT_RUNTIME_DIR="$FOLDER_FOR_DATA/authentik/blueprints"

INVITATION_BLUEPRINT_URL="https://goauthentik.io/blueprints/example/flows-invitation-enrollment.yaml"
ENROLLMENT_2_STAGE_URL="https://goauthentik.io/blueprints/example/flows-enrollment-2-stage.yaml"

echo
echo "✅ Found the following variables / values:"
echo "   - FOLDER_FOR_DATA=$FOLDER_FOR_DATA"
echo "   - PUID=$PUID"
echo "   - PGID=$PGID"
echo "   - BLUEPRINT_RUNTIME_DIR=$BLUEPRINT_RUNTIME_DIR"

echo
echo "Creating live Authentik blueprints folder if required..."
echo
sudo mkdir -p "$BLUEPRINT_RUNTIME_DIR"
sudo chown -R "$PUID:$PGID" "$BLUEPRINT_RUNTIME_DIR"
sudo chmod 2775 "$BLUEPRINT_RUNTIME_DIR"

echo
echo "Downloading official Authentik example blueprints directly into live blueprints folder..."
echo

TMP_INVITATION="$(mktemp)"
TMP_ENROLLMENT="$(mktemp)"
trap 'rm -f "$TMP_INVITATION" "$TMP_ENROLLMENT"' EXIT

if ! curl -fsSL "$INVITATION_BLUEPRINT_URL" -o "$TMP_INVITATION"; then
    echo "❌ Failed to download flows-invitation-enrollment.yaml"
    exit 1
fi

if ! curl -fsSL "$ENROLLMENT_2_STAGE_URL" -o "$TMP_ENROLLMENT"; then
    echo "❌ Failed to download flows-enrollment-2-stage.yaml"
    exit 1
fi

if [ ! -s "$TMP_INVITATION" ]; then
    echo "❌ Downloaded invitation blueprint is empty"
    exit 1
fi

if [ ! -s "$TMP_ENROLLMENT" ]; then
    echo "❌ Downloaded enrollment blueprint is empty"
    exit 1
fi

sudo install -o "$PUID" -g "$PGID" -m 664 "$TMP_INVITATION" \
    "$BLUEPRINT_RUNTIME_DIR/flows-invitation-enrollment.yaml"

sudo install -o "$PUID" -g "$PGID" -m 664 "$TMP_ENROLLMENT" \
    "$BLUEPRINT_RUNTIME_DIR/flows-enrollment-2-stage.yaml"

if [ -f "$BLUEPRINT_RUNTIME_DIR/flows-invitation-enrollment.yaml" ] && \
   [ -f "$BLUEPRINT_RUNTIME_DIR/flows-enrollment-2-stage.yaml" ]; then
    echo
    echo "✅ Official Authentik blueprint files downloaded successfully to:"
    echo "   $BLUEPRINT_RUNTIME_DIR"
    echo
else
    echo
    echo "❌ One or more blueprint files were not copied successfully"
    exit 1
fi
