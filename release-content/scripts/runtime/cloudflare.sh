#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# -----------------------------------------------------------------------------
# MediaStack Cloudflare Helper
#
# Purpose:
# - Validate Cloudflare settings from .env
# - Detect external IP and optionally allow manual override
# - Test zone access and token permissions with a temporary TXT record
# - Discover MediaStack hostnames from `docker compose config`
# - Show current zone records
# - Delete existing MediaStack-managed DNS records
# - Create MediaStack DNS records:
#     * Apex/TLD as A record -> detected IP
#     * All service hosts as CNAME -> apex
# - All records are DNS only (proxied=false)
# -----------------------------------------------------------------------------

say()   { echo "$*"; }
info()  { echo "[INFO] $*"; }
pass()  { echo "[PASS] $*"; }
warn()  { echo "[WARN] $*"; }
fail()  { echo "[FAIL] $*"; }

pause_line() {
    echo
}

confirm() {
    local prompt="$1"
    echo
    read -r -p "$prompt [y/N]: " reply
    [[ "${reply,,}" == "y" ]]
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fail "Required command not found: $cmd"
        exit 1
    fi
}

if [[ ! -f "$ENV_FILE" ]]; then
    fail ".env file not found in $SCRIPT_DIR/"
    exit 1
fi

get_env_value() {
    local var_name="$1"
    grep -E "^${var_name}=" "$ENV_FILE" 2>/dev/null \
        | tail -n 1 \
        | cut -d '=' -f2- \
        | sed 's/^[[:space:]]*//; s/[[:space:]]*#.*//' \
        | sed 's/^"//; s/"$//' \
        | tr -d '\r' || true
}

require_cmd curl
require_cmd docker
require_cmd sed
require_cmd awk
require_cmd grep

CLOUDFLARE_EMAIL="$(get_env_value "CLOUDFLARE_EMAIL")"
CLOUDFLARE_DNS_ZONE="$(get_env_value "CLOUDFLARE_DNS_ZONE")"
CLOUDFLARE_DNS_API_TOKEN="$(get_env_value "CLOUDFLARE_DNS_API_TOKEN")"

MISSING_VARS=()
[[ -z "$CLOUDFLARE_DNS_ZONE" ]]      && MISSING_VARS+=("CLOUDFLARE_DNS_ZONE")
[[ -z "$CLOUDFLARE_DNS_API_TOKEN" ]] && MISSING_VARS+=("CLOUDFLARE_DNS_API_TOKEN")

if [[ ${#MISSING_VARS[@]} -ne 0 ]]; then
    fail "The following required variables are missing or empty in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

pause_line
pass "Found Cloudflare configuration values in .env"
[[ -n "$CLOUDFLARE_EMAIL" ]] && info "CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL"
info "CLOUDFLARE_DNS_ZONE=$CLOUDFLARE_DNS_ZONE"
info "CLOUDFLARE_DNS_API_TOKEN=<redacted>"

CF_API="https://api.cloudflare.com/client/v4"
ZONE_ID=""
DETECTED_IP=""
ACTIVE_IP=""

cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [[ -n "$data" ]]; then
        curl -sS -X "$method" "$CF_API$endpoint" \
            -H "Authorization: Bearer $CLOUDFLARE_DNS_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "$data"
    else
        curl -sS -X "$method" "$CF_API$endpoint" \
            -H "Authorization: Bearer $CLOUDFLARE_DNS_API_TOKEN" \
            -H "Content-Type: application/json"
    fi
}

cf_result_success() {
    grep -q '"success":true'
}

get_zone_id() {
    local response
    response="$(cf_api GET "/zones?name=${CLOUDFLARE_DNS_ZONE}&status=active")"
    if ! echo "$response" | cf_result_success; then
        fail "Cloudflare zone lookup failed"
        echo "$response"
        return 1
    fi

    local zone_id
    zone_id="$(echo "$response" | sed -n 's/.*"result":\[{"id":"\([^"]*\)".*/\1/p')"
    if [[ -z "$zone_id" ]]; then
        fail "Could not determine Cloudflare zone ID for $CLOUDFLARE_DNS_ZONE"
        return 1
    fi

    ZONE_ID="$zone_id"
    pass "Cloudflare zone access works"
    info "Zone ID: $ZONE_ID"
}

list_zone_records() {
    local response
    response="$(cf_api GET "/zones/${ZONE_ID}/dns_records?per_page=500")"
    if ! echo "$response" | cf_result_success; then
        fail "Could not list DNS records in the zone"
        echo "$response"
        return 1
    fi

    echo "$response" \
        | tr '{' '\n' \
        | grep '"type":"' \
        | sed -n 's/.*"type":"\([^"]*\)".*"name":"\([^"]*\)".*"content":"\([^"]*\)".*"proxied":\([^,}]*\).*/\1 | \2 | \3 | proxied=\4/p' \
        | sort || true
}

create_txt_permission_test() {
    local ts test_name test_value payload response record_id delete_response
    ts="$(date +%s)"
    test_name="_mediastack-permission-test.${CLOUDFLARE_DNS_ZONE}"
    test_value="mediastack-${ts}"

    payload="$(cat <<JSON
{"type":"TXT","name":"${test_name}","content":"${test_value}","ttl":120,"proxied":false}
JSON
)"
    response="$(cf_api POST "/zones/${ZONE_ID}/dns_records" "$payload")"

    if ! echo "$response" | cf_result_success; then
        fail "Cloudflare TXT create/delete permission test failed"
        echo "$response"
        return 1
    fi

    record_id="$(echo "$response" | sed -n 's/.*"result":{.*"id":"\([^"]*\)".*/\1/p')"
    if [[ -z "$record_id" ]]; then
        fail "TXT permission test created a record but no record ID was returned"
        return 1
    fi

    pass "TXT create permission passed"

    delete_response="$(cf_api DELETE "/zones/${ZONE_ID}/dns_records/${record_id}")"
    if ! echo "$delete_response" | cf_result_success; then
        fail "TXT delete permission test failed"
        echo "$delete_response"
        return 1
    fi

    pass "TXT delete permission passed"
    return 0
}

detect_external_ip() {
    DETECTED_IP="$(curl -4 -sS ifconfig.io || true)"
    if [[ -z "$DETECTED_IP" ]]; then
        warn "Could not detect external IP from ifconfig.io"
        ACTIVE_IP=""
        return
    fi
    pass "Detected external IP: $DETECTED_IP"
    ACTIVE_IP="$DETECTED_IP"
}

override_ip_if_requested() {
    if confirm "Change detected IP address in case of error?"; then
        read -r -p "Enter IPv4 address to use: " manual_ip
        if [[ -n "$manual_ip" ]]; then
            ACTIVE_IP="$manual_ip"
            pass "Using manual IP address: $ACTIVE_IP"
        else
            warn "No manual IP entered. Keeping detected value."
        fi
    fi
}

extract_compose_hosts() {
    local cfg
    cfg="$(docker compose config 2>/dev/null || true)"
    if [[ -z "$cfg" ]]; then
        warn "docker compose config produced no output"
        return 0
    fi

    echo "$cfg" \
        | grep -oE 'Host\(`[^`]+`\)' \
        | sed -E 's/Host\(`([^`]+)`\)/\1/' \
        | sort -u
}

display_potential_dns_entries() {
    local hosts
    hosts="$(extract_compose_hosts || true)"

    echo
    echo "Potential MediaStack DNS hostnames from docker compose config:"
    echo "-------------------------------------------------------------"
    if [[ -z "$hosts" ]]; then
        warn "No Host() entries were discovered from docker compose config"
        return 0
    fi
    echo "$hosts"
}

get_mediastack_hosts() {
    extract_compose_hosts || true
}

get_existing_zone_records_json() {
    cf_api GET "/zones/${ZONE_ID}/dns_records?per_page=500"
}

delete_dns_record_by_id() {
    local record_id="$1"
    cf_api DELETE "/zones/${ZONE_ID}/dns_records/${record_id}" >/dev/null
}

delete_mediastack_dns_entries() {
    local response host
    response="$(get_existing_zone_records_json)"
    if ! echo "$response" | cf_result_success; then
        fail "Could not fetch current zone records for delete operation"
        echo "$response"
        return 1
    fi

    local apex="$CLOUDFLARE_DNS_ZONE"
    local host_list
    host_list="$(get_mediastack_hosts || true)"

    if [[ -z "$host_list" ]]; then
        warn "No MediaStack hosts discovered from docker compose config"
        return 0
    fi

    while IFS= read -r host; do
        [[ -z "$host" ]] && continue
        echo "$response" \
            | tr '{' '\n' \
            | sed -n 's/.*"id":"\([^"]*\)".*"type":"\([^"]*\)".*"name":"'"$host"'".*/\1|\2|'"$host"'/p' \
            | while IFS='|' read -r record_id record_type record_name; do
                [[ -z "$record_id" ]] && continue
                info "Deleting DNS record: $record_type $record_name"
                delete_dns_record_by_id "$record_id" || true
            done
    done <<< "$host_list"

    echo "$response" \
        | tr '{' '\n' \
        | sed -n 's/.*"id":"\([^"]*\)".*"type":"\([^"]*\)".*"name":"'"$apex"'".*/\1|\2|'"$apex"'/p' \
        | while IFS='|' read -r record_id record_type record_name; do
            [[ -z "$record_id" ]] && continue
            info "Deleting apex DNS record: $record_type $record_name"
            delete_dns_record_by_id "$record_id" || true
        done

    pass "Requested MediaStack DNS entries deleted"
}

upsert_apex_a_record() {
    local payload response list_response record_id
    payload="$(cat <<JSON
{"type":"A","name":"${CLOUDFLARE_DNS_ZONE}","content":"${ACTIVE_IP}","ttl":1,"proxied":false}
JSON
)"
    response="$(cf_api POST "/zones/${ZONE_ID}/dns_records" "$payload")"
    if echo "$response" | cf_result_success; then
        pass "Created apex A record: ${CLOUDFLARE_DNS_ZONE} -> ${ACTIVE_IP}"
        return 0
    fi

    list_response="$(cf_api GET "/zones/${ZONE_ID}/dns_records?type=A&name=${CLOUDFLARE_DNS_ZONE}")"
    record_id="$(echo "$list_response" | sed -n 's/.*"result":\[{"id":"\([^"]*\)".*/\1/p')"
    if [[ -n "$record_id" ]]; then
        response="$(cf_api PUT "/zones/${ZONE_ID}/dns_records/${record_id}" "$payload")"
        if echo "$response" | cf_result_success; then
            pass "Updated apex A record: ${CLOUDFLARE_DNS_ZONE} -> ${ACTIVE_IP}"
            return 0
        fi
    fi

    fail "Could not create or update apex A record"
    echo "$response"
    return 1
}

upsert_cname_record() {
    local host="$1"
    local payload response list_response record_id
    payload="$(cat <<JSON
{"type":"CNAME","name":"${host}","content":"${CLOUDFLARE_DNS_ZONE}","ttl":1,"proxied":false}
JSON
)"
    response="$(cf_api POST "/zones/${ZONE_ID}/dns_records" "$payload")"
    if echo "$response" | cf_result_success; then
        pass "Created CNAME: ${host} -> ${CLOUDFLARE_DNS_ZONE}"
        return 0
    fi

    list_response="$(cf_api GET "/zones/${ZONE_ID}/dns_records?type=CNAME&name=${host}")"
    record_id="$(echo "$list_response" | sed -n 's/.*"result":\[{"id":"\([^"]*\)".*/\1/p')"
    if [[ -n "$record_id" ]]; then
        response="$(cf_api PUT "/zones/${ZONE_ID}/dns_records/${record_id}" "$payload")"
        if echo "$response" | cf_result_success; then
            pass "Updated CNAME: ${host} -> ${CLOUDFLARE_DNS_ZONE}"
            return 0
        fi
    fi

    fail "Could not create or update CNAME for ${host}"
    echo "$response"
    return 1
}

create_mediastack_dns_entries() {
    local hosts host
    if [[ -z "$ACTIVE_IP" ]]; then
        fail "No active IP address is available for apex A record creation"
        return 1
    fi

    upsert_apex_a_record

    hosts="$(get_mediastack_hosts || true)"
    if [[ -z "$hosts" ]]; then
        warn "No MediaStack hosts discovered from docker compose config"
        return 0
    fi

    while IFS= read -r host; do
        [[ -z "$host" ]] && continue
        if [[ "$host" == "$CLOUDFLARE_DNS_ZONE" ]]; then
            continue
        fi
        upsert_cname_record "$host"
    done <<< "$hosts"

    pass "Requested MediaStack DNS entries created/updated"
}

pause_line
say "Press:"
say '   - "y" to continue with Cloudflare checks and actions'
say '   - any other key to exit...'
pause_line
read -n 1 -s -r -p "Your choice: " USER_CHOICE
echo
if [[ "$USER_CHOICE" != "y" ]]; then
    warn "Exiting..."
    exit 0
fi

pause_line
say "============================================================"
say "Cloudflare Zone and Permission Checks"
say "============================================================"

get_zone_id
detect_external_ip
override_ip_if_requested
create_txt_permission_test

if confirm "Display a list of potential DNS entries from docker compose config?"; then
    display_potential_dns_entries
fi

if confirm "Display a list of DNS entries already configured in the Cloudflare zone?"; then
    echo
    echo "Current Cloudflare zone records:"
    echo "-------------------------------"
    list_zone_records || true
fi

if confirm "Delete all MediaStack DNS entries in this zone using docker compose host entries?"; then
    delete_mediastack_dns_entries
fi

if confirm "Create all MediaStack DNS entries in this zone (A on apex, CNAMEs for hosts, DNS only)?"; then
    create_mediastack_dns_entries
fi

pause_line
say "============================================================"
say "Cloudflare helper complete"
say "============================================================"
