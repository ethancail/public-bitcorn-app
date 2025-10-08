#!/bin/bash
set -e

UMBREL_APP_DIR="$HOME/umbrel/app-data/bitcorn-lightning-app"
UMBREL_APPS_DIR="$HOME/umbrel/apps/bitcorn-lightning"

# Display welcome message
echo "================================================================"
echo "BitCorn Lightning App - Installation Script"
echo "================================================================"
echo ""
echo "This script will install BitCorn Lightning on your Umbrel node."
echo "Before continuing, make sure you have your Supabase API key ready."
echo ""
read -p "Press Enter to continue, or Ctrl+C to cancel..."

# Create app directories
mkdir -p $UMBREL_APP_DIR/data
mkdir -p $UMBREL_APPS_DIR

# Prompt for Supabase API key
echo ""
echo "Enter your Supabase API key:"
read -s SUPABASE_KEY
echo ""

# Save environment variables
echo "Saving environment configuration..."
cat > $UMBREL_APP_DIR/.env << EOL
SUPABASE_URL=https://whnijkkttovsozjowkif.supabase.co
SUPABASE_KEY=$SUPABASE_KEY
EOL
chmod 600 $UMBREL_APP_DIR/.env

echo "✓ Environment configuration saved"

# Create docker-compose.yml file directly
echo "Creating Docker configuration..."
cat > $UMBREL_APP_DIR/docker-compose.yml << 'EOL'
services:
  api:
    image: ethanccail/lightning-app:latest
    restart: unless-stopped
    container_name: bitcorn_api_1
    environment:
      PORT: 3001
      SUPABASE_URL: ${SUPABASE_URL:-https://whnijkkttovsozjowkif.supabase.co}
      SUPABASE_KEY: ${SUPABASE_KEY}
      # LND connection settings
      LND_GRPC_HOST: "127.0.0.1:10009"
      LND_TLS_CERT_PATH: "/lnd/tls.cert"
      LND_MACAROON_PATH: "/lnd/data/chain/bitcoin/mainnet/admin.macaroon"
      LND_ADMIN_MACAROON_PATH: "/lnd/data/chain/bitcoin/mainnet/admin.macaroon"
      LNSERVICE_CHAIN: bitcoin
      LNSERVICE_NETWORK: mainnet
      LNSERVICE_TLS_DISABLE: "true"
    volumes:
      - ./data:/data
      - /home/umbrel/umbrel/app-data/lightning/data/lnd/tls.cert:/lnd/tls.cert:ro
      - /home/umbrel/umbrel/app-data/lightning/data/lnd/data/chain/bitcoin/mainnet:/lnd/data/chain/bitcoin/mainnet:ro
    network_mode: "host"
EOL

# Create umbrel-app.yml for dashboard integration
echo "Creating app metadata for Umbrel dashboard..."
cat > $UMBREL_APPS_DIR/umbrel-app.yml << EOL
manifestVersion: 1
id: bitcorn-lightning
category: finance
name: BitCorn Lightning
version: "1.0.0"
tagline: Bitcoin & Lightning for Grain Sales
description: >-
  Manage Bitcoin Lightning transactions between grain merchants and farmers.
  Generate invoices, track payments, and process withdrawal requests.
developer: BitCorn Technologies Inc.
website: https://github.com/ethancail/public-bitcorn-app
dependencies:
  - lightning
repo: https://github.com/ethancail/public-bitcorn-app
support: https://github.com/ethancail/public-bitcorn-app/issues
port: 3001
EOL

# Download app icon
echo "Downloading app icon..."
curl -s -o $UMBREL_APPS_DIR/icon.png https://raw.githubusercontent.com/ethancail/public-bitcorn-app/main/assets/icon.png

# Register the app in Umbrel's app list
UMBREL_APP_DATA="$HOME/umbrel/app-data.json"
if [ -f "$UMBREL_APP_DATA" ]; then
  echo "Registering app with Umbrel dashboard..."
  TMP_FILE=$(mktemp)
  jq ".apps += {\"bitcorn-lightning\": {\"id\": \"bitcorn-lightning\", \"name\": \"BitCorn Lightning\", \"icon\": \"/apps/bitcorn-lightning/icon.png\", \"port\": 3001}}" $UMBREL_APP_DATA > $TMP_FILE
  mv $TMP_FILE $UMBREL_APP_DATA
fi

# Start the container
echo "Starting BitCorn Lightning App..."
cd $UMBREL_APP_DIR
docker compose pull
docker compose up -d

echo ""
echo "================================================================"
echo "BitCorn Lightning has been installed!"
echo "Access your app at: http://umbrel.local:3001"
echo "You should now see BitCorn Lightning in your Umbrel dashboard"
echo "================================================================"