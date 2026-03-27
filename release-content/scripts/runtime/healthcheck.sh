#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
    echo "[WARN] $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

section() {
    echo
    echo "=================================================================="
    echo "$1"
    echo "=================================================================="
}

get_env_value() {
    local key="$1"
    grep -E "^${key}=" "$ENV_FILE" | head -n1 | cut -d'=' -f2- | sed 's/^"//; s/"$//'
}

section "MediaStack Health Check"

if [[ ! -f "$ENV_FILE" ]]; then
    fail "No .env file found in runtime directory: $SCRIPT_DIR"
    echo
    echo "Health check cannot continue without .env"
    exit 1
fi

pass ".env file found in runtime directory"

FOLDER_FOR_MEDIA="$(get_env_value "FOLDER_FOR_MEDIA" || true)"
FOLDER_FOR_APPDATA="$(get_env_value "FOLDER_FOR_APPDATA" || true)"
FOLDER_FOR_RUNTIME="$(get_env_value "FOLDER_FOR_RUNTIME" || true)"

section "Docker Checks"

if ! docker info >/dev/null 2>&1; then
    fail "Docker daemon is not reachable"
    echo
    echo "Summary: ${PASS_COUNT} pass, ${WARN_COUNT} warn, ${FAIL_COUNT} fail"
    exit 1
fi

pass "Docker daemon is reachable"

if docker compose config >/dev/null 2>&1; then
    pass "docker compose config validation passed"
else
    fail "docker compose config validation failed"
fi

section "Folder Checks"

check_folder() {
    local label="$1"
    local path="$2"

    if [[ -z "$path" ]]; then
        fail "$label is missing from .env"
        return
    fi

    if [[ -d "$path" ]]; then
        pass "$label exists: $path"
    else
        warn "$label does not exist yet: $path"
        echo "       This may be expected before first run of restart.sh"
    fi
}

check_folder "FOLDER_FOR_MEDIA" "$FOLDER_FOR_MEDIA"
check_folder "FOLDER_FOR_APPDATA" "$FOLDER_FOR_APPDATA"
check_folder "FOLDER_FOR_RUNTIME" "$FOLDER_FOR_RUNTIME"

section "Disk Space"

df -h .

if [[ -n "$FOLDER_FOR_MEDIA" && -d "$FOLDER_FOR_MEDIA" ]]; then
    df -h "$FOLDER_FOR_MEDIA" || true
fi

if [[ -n "$FOLDER_FOR_APPDATA" && -d "$FOLDER_FOR_APPDATA" ]]; then
    df -h "$FOLDER_FOR_APPDATA" || true
fi

section "Container Status"

if docker compose ps >/dev/null 2>&1; then
    docker compose ps

    mapfile -t EXPECTED_SERVICES < <(docker compose config --services)

    for SERVICE in "${EXPECTED_SERVICES[@]}"; do
        CONTAINER_ID="$(docker compose ps -q "$SERVICE" 2>/dev/null || true)"

        if [[ -z "$CONTAINER_ID" ]]; then
            warn "Service not created yet: $SERVICE"
            continue
        fi

        STATUS="$(docker inspect --format='{{.State.Status}}' "$CONTAINER_ID" 2>/dev/null || true)"
        HEALTH="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CONTAINER_ID" 2>/dev/null || true)"

        if [[ "$STATUS" == "running" ]]; then
            if [[ "$HEALTH" == "unhealthy" ]]; then
                fail "Service unhealthy: $SERVICE"
            elif [[ "$HEALTH" == "starting" ]]; then
                warn "Service health still starting: $SERVICE"
            else
                pass "Service running: $SERVICE"
            fi
        elif [[ "$STATUS" == "restarting" ]]; then
            fail "Service restarting: $SERVICE"
        elif [[ "$STATUS" == "exited" ]]; then
            fail "Service exited: $SERVICE"
        else
            warn "Service state $STATUS: $SERVICE"
        fi
    done
else
    fail "docker compose ps failed"
fi

section "Recent Container Problems"

docker compose ps --all || true
echo
docker ps --filter "health=unhealthy" || true

section "Summary"

echo "Pass: $PASS_COUNT"
echo "Warn: $WARN_COUNT"
echo "Fail: $FAIL_COUNT"

echo
if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo "Overall result: FAIL"
    exit 1
elif [[ "$WARN_COUNT" -gt 0 ]]; then
    echo "Overall result: WARN"
    exit 0
else
    echo "Overall result: PASS"
    exit 0
fi