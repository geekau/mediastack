#!/usr/bin/env bash
set -e

POSTGRESQL_CONTAINER="postgresql"
ENV_FILE=".env"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $(pwd)/"
    exit 1
fi

# Read values from .env and clean them
GUACOMOLE_DATABASE=$(grep  -E '^GUACAMOLE_DATABASE='  "$ENV_FILE" | cut -d '=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*#.*//' | tr -d '\r')
POSTGRESQL_USERNAME=$(grep -E '^POSTGRESQL_USERNAME=' "$ENV_FILE" | cut -d '=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*#.*//' | tr -d '\r')
POSTGRESQL_PASSWORD=$(grep -E '^POSTGRESQL_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*#.*//' | tr -d '\r')

# Validate required vars
MISSING_VARS=()
[ -z "$GUACAMOLE_DATABASE" ]  && MISSING_VARS+=("GUACAMOLE_DATABASE")
[ -z "$POSTGRESQL_USERNAME" ] && MISSING_VARS+=("POSTGRESQL_USERNAME")
[ -z "$POSTGRESQL_PASSWORD" ] && MISSING_VARS+=("POSTGRESQL_PASSWORD")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: The following required variables are missing or empty in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

echo "✅ Found the following variables / values:"
echo "   - GUACAMOLE_DATABASE=$GUACAMOLE_DATABASE"
echo "   - POSTGRESQL_USERNAME=$POSTGRESQL_USERNAME"
echo "   - POSTGRESQL_PASSWORD=$POSTGRESQL_PASSWORD"

echo
echo Press:
echo    - \"y\" to create a new database for Guacamole, using above settings.
echo    - any other key to finish update...
echo
read -n 1 -s -r -p "Your choice: " USER_CHOICE
echo
if [[ "$USER_CHOICE" != "y" ]]; then
    echo "❌ Exiting..."
    echo
    exit 0
fi

# Check if database exists
echo "🔍 Checking if database '$GUACAMOLE_DATABASE' already exists..."
if sudo docker exec -e PGPASSWORD="$POSTGRESQL_PASSWORD" "$POSTGRESQL_CONTAINER" \
    psql -U "$POSTGRESQL_USERNAME" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$GUACAMOLE_DATABASE';" | grep -q 1; then
    echo "✅ Database '$GUACAMOLE_DATABASE' already exists. Skipping creation."
    exit 0
fi

# Create the database
echo "📦 Creating database '$GUACAMOLE_DATABASE'..."
sudo docker exec -e PGPASSWORD="$POSTGRESQL_PASSWORD" "$POSTGRESQL_CONTAINER" \
    psql -U "$POSTGRESQL_USERNAME" -d postgres -c "CREATE DATABASE \"$GUACAMOLE_DATABASE\";"

# Grant permissions to database
sudo docker exec -e PGPASSWORD="$ADMIN_PASSWORD" -i "$POSTGRESQL_CONTAINER" psql -U "$POSTGRESQL_USERNAME" -d "$GUACAMOLE_DATABASE" <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$POSTGRESQL_USERNAME') THEN
      CREATE USER "$POSTGRESQL_USERNAME" WITH PASSWORD '$POSTGRESQL_PASSWORD';
   END IF;
END
\$\$;

GRANT CONNECT ON DATABASE "$GUACAMOLE_DATABASE" TO "$POSTGRESQL_USERNAME";
GRANT USAGE ON SCHEMA public TO "$POSTGRESQL_USERNAME";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "$POSTGRESQL_USERNAME";
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO "$POSTGRESQL_USERNAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "$POSTGRESQL_USERNAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO "$POSTGRESQL_USERNAME";
EOF

# Initialise the schema
echo "⚙️  Initialising Guacamole schema in '$GUACAMOLE_DATABASE'..."
sudo docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql | \
sudo docker exec -e PGPASSWORD="$POSTGRESQL_PASSWORD" -i "$POSTGRESQL_CONTAINER" \
     psql -U "$POSTGRESQL_USERNAME" -d "$GUACAMOLE_DATABASE"
echo "✅ Database '$GUACAMOLE_DATABASE' created and initialised successfully."

echo 
echo 
sudo docker exec postgresql psql -U "$POSTGRESQL_USERNAME" -l
echo 
