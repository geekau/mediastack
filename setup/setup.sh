#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
DOCKER_FILE="$SCRIPT_DIR/../docker-compose.yaml"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Check if docker-compose.yaml exists
if [ ! -f "$DOCKER_FILE" ]; then
    echo "❌ Error: docker-compose.yaml file not found at $DOCKER_FILE"
    exit 1
fi

# Read values from .env and clean them
get_env_value() {
    local VAR_NAME="$1"
    grep -E "^${VAR_NAME}=" "$ENV_FILE" | cut -d '=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*#.*//' | tr -d '\r' | tail -n 1
}

FOLDER_FOR_CONFIG=$(get_env_value        "FOLDER_FOR_CONFIG")
FOLDER_FOR_MEDIA=$(get_env_value         "FOLDER_FOR_MEDIA")
FOLDER_FOR_DATA=$(get_env_value          "FOLDER_FOR_DATA")
LOCAL_DOCKER_IP=$(get_env_value          "LOCAL_DOCKER_IP")
CLOUDFLARE_EMAIL=$(get_env_value         "CLOUDFLARE_EMAIL")
CLOUDFLARE_DNS_ZONE=$(get_env_value      "CLOUDFLARE_DNS_ZONE")
CLOUDFLARE_DNS_API_TOKEN=$(get_env_value "CLOUDFLARE_DNS_API_TOKEN")
AUTHENTIK_SECRET_KEY=$(get_env_value     "AUTHENTIK_SECRET_KEY")
POSTGRESQL_PASSWORD=$(get_env_value      "POSTGRESQL_PASSWORD")
EMAIL_SERVER_HOST=$(get_env_value        "EMAIL_SERVER_HOST")
EMAIL_ADDRESS=$(get_env_value            "EMAIL_ADDRESS")
EMAIL_PASSWORD=$(get_env_value           "EMAIL_PASSWORD")
EMAIL_SENDER=$(get_env_value             "EMAIL_SENDER")

# Validate required vars
MISSING_VARS=()
[ -z "$FOLDER_FOR_CONFIG" ]        && MISSING_VARS+=("FOLDER_FOR_CONFIG")
[ -z "$FOLDER_FOR_MEDIA" ]         && MISSING_VARS+=("FOLDER_FOR_MEDIA")
[ -z "$FOLDER_FOR_DATA" ]          && MISSING_VARS+=("FOLDER_FOR_DATA")
[ -z "$LOCAL_DOCKER_IP" ]          && MISSING_VARS+=("LOCAL_DOCKER_IP")
[ -z "$CLOUDFLARE_EMAIL" ]         && MISSING_VARS+=("CLOUDFLARE_EMAIL")
[ -z "$CLOUDFLARE_DNS_ZONE" ]      && MISSING_VARS+=("CLOUDFLARE_DNS_ZONE")
[ -z "$CLOUDFLARE_DNS_API_TOKEN" ] && MISSING_VARS+=("CLOUDFLARE_DNS_API_TOKEN")
[ -z "$AUTHENTIK_SECRET_KEY" ]     && MISSING_VARS+=("AUTHENTIK_SECRET_KEY")
[ -z "$POSTGRESQL_PASSWORD" ]      && MISSING_VARS+=("POSTGRESQL_PASSWORD")
[ -z "$EMAIL_SERVER_HOST" ]        && MISSING_VARS+=("EMAIL_SERVER_HOST")
[ -z "$EMAIL_ADDRESS" ]            && MISSING_VARS+=("EMAIL_ADDRESS")
[ -z "$EMAIL_PASSWORD" ]           && MISSING_VARS+=("EMAIL_PASSWORD")
[ -z "$EMAIL_SENDER" ]             && MISSING_VARS+=("EMAIL_SENDER")

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
echo
echo "   - LOCAL_DOCKER_IP=$LOCAL_DOCKER_IP"
echo "   - CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL"
echo "   - CLOUDFLARE_DNS_ZONE=$CLOUDFLARE_DNS_ZONE"
echo "   - CLOUDFLARE_DNS_API_TOKEN=$CLOUDFLARE_DNS_API_TOKEN"
echo
echo "   - AUTHENTIK_SECRET_KEY=$AUTHENTIK_SECRET_KEY"
echo "   - POSTGRESQL_PASSWORD=$POSTGRESQL_PASSWORD"
echo
echo "   - EMAIL_SERVER_HOST=$EMAIL_SERVER_HOST"
echo "   - EMAIL_ADDRESS=$EMAIL_ADDRESS"
echo "   - EMAIL_PASSWORD=$EMAIL_PASSWORD"
echo "   - EMAIL_SENDER=$EMAIL_SENDER"

echo
echo "🔍 Checking IP Address Configuration..."

# Function to detect if IP is static or dynamic
detect_ip_type() {
    local ip_to_check="$1"
    local interface=""
    
    # Get the network interface for the IP
    interface=$(ip -o addr show | grep "$ip_to_check" | awk '{print $2}' | head -1)
    
    if [ -z "$interface" ]; then
        echo "⚠️  IP '$ip_to_check' is not currently assigned to any network interface"
        echo "   (It may be assigned to a Docker interface or virtual network)"
        return
    fi
    
    # Check netplan configuration (Ubuntu/Debian modern)
    if [ -d "/etc/netplan" ]; then
        for file in /etc/netplan/*.yaml /etc/netplan/*.yml; do
            if [ -f "$file" ] && grep -q "dhcp4\|dhcp6" "$file"; then
                if grep -q "dhcp4: true\|dhcp6: true" "$file"; then
                    echo "⚠️  IP Detection: DYNAMIC (DHCP enabled in netplan)"
                    echo "   ⚠️  WARNING: Using DHCP is not recommended for server/Docker host"
                    echo "   💡 Recommendation: Configure a static IP for stability"
                    return
                fi
            fi
        done
    fi
    
    # Check NetworkManager configuration
    if command -v nmcli &> /dev/null; then
        local nm_method=$(nmcli device show "$interface" 2>/dev/null | grep "IP4.DHCP" | awk '{print $2}')
        if [ "$nm_method" = "yes" ]; then
            echo "⚠️  IP Detection: DYNAMIC (DHCP via NetworkManager)"
            echo "   ⚠️  WARNING: Using DHCP is not recommended for server/Docker host"
            echo "   💡 Recommendation: Configure a static IP for stability"
            return
        fi
    fi
    
    # Check /etc/network/interfaces (Debian/Ubuntu legacy)
    if [ -f "/etc/network/interfaces" ]; then
        if grep -q "auto $interface" "/etc/network/interfaces"; then
            if grep -A5 "auto $interface" "/etc/network/interfaces" | grep -q "dhcp"; then
                echo "⚠️  IP Detection: DYNAMIC (DHCP in /etc/network/interfaces)"
                echo "   ⚠️  WARNING: Using DHCP is not recommended for server/Docker host"
                echo "   💡 Recommendation: Configure a static IP for stability"
                return
            fi
        fi
    fi
    
    # Check dhclient leases
    if [ -f "/var/lib/dhcp/dhclient.leases" ] || [ -f "/var/lib/dhclient/dhclient.leases" ]; then
        if grep -q "$ip_to_check" /var/lib/dhcp/dhclient.leases 2>/dev/null || grep -q "$ip_to_check" /var/lib/dhclient/dhclient.leases 2>/dev/null; then
            echo "⚠️  IP Detection: DYNAMIC (Active DHCP lease found)"
            echo "   ⚠️  WARNING: Using DHCP is not recommended for server/Docker host"
            echo "   💡 Recommendation: Configure a static IP for stability"
            echo
            return
        fi
    fi
    
    # If we get here, assume static
    echo "✅ IP Detection: STATIC (Appears to be statically configured)"
    echo "   ✅ Good: Static IP is recommended for server/Docker host"
    echo
}

detect_ip_type "$LOCAL_DOCKER_IP"

# Rewrite host portion of any http(s):// URL to use local docker IP
cp Internal_Bookmarks.html "$FOLDER_FOR_CONFIG/MediaStack_Internal_Bookmarks.html"
sed -i -E "s|(https?://)[^/:]+|\1$LOCAL_DOCKER_IP|g" "$FOLDER_FOR_CONFIG/MediaStack_Internal_Bookmarks.html"

# Copy external bookmarks and replace YOUR_DOMAIN_NAME with CLOUDFLARE_DNS_ZONE
cp External_Bookmarks.html "$FOLDER_FOR_CONFIG/MediaStack_External_Bookmarks.html"
sed -i "s|YOUR_DOMAIN_NAME|$CLOUDFLARE_DNS_ZONE|g" "$FOLDER_FOR_CONFIG/MediaStack_External_Bookmarks.html"







