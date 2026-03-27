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

echo
echo Press:
echo    - \"y\" to restart all MediaStack services, using above settings.
echo    - any other key to exit...
echo
read -n 1 -s -r -p "Your choice: " USER_CHOICE
echo
if [[ "$USER_CHOICE" != "y" ]]; then
    echo "❌ Exiting..."
    echo
    exit 0
fi

echo
echo Creating folders and setting permissions...
echo

sudo mkdir -p $FOLDER_FOR_RUNTIME
sudo mkdir -p $FOLDER_FOR_APPDATA/{authentik/{blueprints,certs,media,templates},bazarr,chromium,crowdsec/{acquis.d,appsec-configs,appsec-rules,data},ddns-updater,filebot,flaresolverr,gluetun,grafana,headplane/data,headscale/data,heimdall,homarr/{configs,data,icons},homepage,jellyfin,seerr,lazylibrarian,lidarr,logs/{unpackerr,traefik},mylar,plex,portainer,postgresql,prometheus,prowlarr,qbittorrent,radarr,sabnzbd,sonarr,tailscale,tdarr/{server,configs,logs},tdarr-node,traefik/letsencrypt,traefik-certs-dumper,unpackerr,valkey,whisparr}
sudo mkdir -p $FOLDER_FOR_MEDIA/media/{anime,audiobooks,books,comics,movies,music,photos,tv,xxx}
sudo mkdir -p $FOLDER_FOR_MEDIA/usenet/{anime,audiobooks,books,comics,complete,console,incomplete,movies,music,prowlarr,software,tv,xxx}
sudo mkdir -p $FOLDER_FOR_MEDIA/torrents/{anime,audiobooks,books,comics,complete,console,incomplete,movies,music,prowlarr,software,tv,xxx}
sudo mkdir -p $FOLDER_FOR_MEDIA/watch
sudo mkdir -p $FOLDER_FOR_MEDIA/filebot/{input,output}
sudo chmod 2775            $FOLDER_FOR_RUNTIME
sudo chown $PUID:$PGID     $FOLDER_FOR_RUNTIME
sudo chmod -R 2775         $FOLDER_FOR_MEDIA $FOLDER_FOR_APPDATA
sudo chown -R $PUID:$PGID  $FOLDER_FOR_MEDIA $FOLDER_FOR_APPDATA

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

echo
echo Moving configuration files into application folders...
echo
sudo chmod 664                   $FOLDER_FOR_RUNTIME/.env $FOLDER_FOR_RUNTIME/*yaml
sudo chown $PUID:$PGID           $FOLDER_FOR_RUNTIME/.env $FOLDER_FOR_RUNTIME/*yaml $FOLDER_FOR_RUNTIME/*sh
sudo touch                       $FOLDER_FOR_APPDATA/traefik/letsencrypt/acme.json
sudo chmod 600                   $FOLDER_FOR_APPDATA/traefik/letsencrypt/acme.json  && echo "Permissions set to 600 on certs file $FOLDER_FOR_APPDATA/traefik/letsencrypt/acme.json"
sudo cp -a headplane-config.yaml $FOLDER_FOR_APPDATA/headplane/config.yaml          && echo "File headplane-config.yaml copied to $FOLDER_FOR_APPDATA/headplane/config.yaml"
sudo cp -a headscale-config.yaml $FOLDER_FOR_APPDATA/headscale/config.yaml          && echo "File headscale-config.yaml copied to $FOLDER_FOR_APPDATA/headscale/config.yaml"
sudo cp -a traefik-static.yaml   $FOLDER_FOR_APPDATA/traefik/traefik.yaml           && echo "File traefik-static.yaml   copied to $FOLDER_FOR_APPDATA/traefik/traefik.yaml"
sudo cp -a traefik-dynamic.yaml  $FOLDER_FOR_APPDATA/traefik/dynamic.yaml           && echo "File traefik-dynamic.yaml  copied to $FOLDER_FOR_APPDATA/traefik/dynamic.yaml"
sudo cp -a traefik-internal.yaml $FOLDER_FOR_APPDATA/traefik/internal.yaml          && echo "File traefik-internal.yaml copied to $FOLDER_FOR_APPDATA/traefik/internal.yaml"
sudo cp -a crowdsec-appsec.yaml  $FOLDER_FOR_APPDATA/crowdsec/acquis.d/appsec.yaml  && echo "File crowdsec-appsec.yaml  copied to $FOLDER_FOR_APPDATA/crowdsec/acquis.d/appsec.yaml"
sudo cp -a crowdsec-traefik.yaml $FOLDER_FOR_APPDATA/crowdsec/acquis.d/traefik.yaml && echo "File crowdsec-traefik.yaml copied to $FOLDER_FOR_APPDATA/crowdsec/acquis.d/traefik.yaml"
sudo cp -a crowdsec-appsec-rules-local.yaml  $FOLDER_FOR_APPDATA/crowdsec/appsec-configs/appsec-rules-local.yaml    \
        && echo "File crowdsec-appsec-rules-local.yaml copied to $FOLDER_FOR_APPDATA/crowdsec/appsec-rules/appsec-rules-local.yaml"

echo
echo "Shutting down all MediaStack containers and removing orphans..."
echo
docker compose down --remove-orphans --timeout 15

echo
echo "Recreating all MediaStack containers and networks..."
echo
if ! docker compose up -d --force-recreate --remove-orphans; then
    echo 'Command "docker compose up -d --force-recreate --remove-orphans" failed... exiting!'
    exit 1
fi

echo
echo "Checking all MediaStack containers are active..."
echo

EXPECTED_SERVICES=$(docker compose config --services)
FAILED=0

for SERVICE in $EXPECTED_SERVICES; do
    CIDS="$(docker compose ps -q "$SERVICE" || true)"

    if [[ -z "$CIDS" ]]; then
        echo
        echo "Docker service $SERVICE has no container (not created / profile disabled / failed early)."
        FAILED=1
        continue
    fi

    # Check each container for this service
    while read -r CID; do
        [[ -z "$CID" ]] && continue
        RUNNING="$(docker inspect --format='{{.State.Running}}' "$CID" 2>/dev/null || echo "false")"
        HEALTH="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$CID" 2>/dev/null || echo "unknown")"

        if [[ "$RUNNING" != "true" ]]; then
            echo
            echo "MediaStack container for service $SERVICE is not running (cid=$CID, health=$HEALTH)."
            FAILED=1
        else
            echo "OK: $SERVICE running (cid=$CID, health=$HEALTH)"
        fi
    done <<< "$CIDS"
done

if [[ $FAILED -eq 0 ]]; then
    echo
    echo "All MediaStack containers are running... ✅"
    echo
else
    echo
    echo "One or more MediaStack services failed to start... ❌"
    echo
    docker compose ps
    echo
    docker compose logs --tail=200
    exit 1
fi
