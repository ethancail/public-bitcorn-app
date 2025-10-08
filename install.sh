#!/bin/bash
set -e

# Set paths
UMBREL_DIR="/home/umbrel/umbrel"
UMBREL_APP_DIR="$UMBREL_DIR/app-data/bitcorn-lightning-app"
UMBREL_APPS_DIR="$UMBREL_DIR/apps/bitcorn-lightning"

# Display welcome message
echo "================================================================"
echo "BitCorn Lightning App - Installation Script"
echo "================================================================"
echo ""
echo "This script will install BitCorn Lightning on your Umbrel node."
echo "Before continuing, make sure you have your Supabase API key ready."
echo ""
read -p "Press Enter to continue, or Ctrl+C to cancel..."

# Create app directory (no sudo required for app-data)
mkdir -p $UMBREL_APP_DIR/data

# Try to create apps directory with sudo if needed
echo "Creating app icon directory (may require sudo)..."
if [ ! -d "$UMBREL_APPS_DIR" ]; then
  sudo mkdir -p $UMBREL_APPS_DIR || {
    echo "Could not create $UMBREL_APPS_DIR - will continue without dashboard icon"
  }
  # Make sure umbrel user owns the directory
  if [ -d "$UMBREL_APPS_DIR" ]; then
    sudo chown -R umbrel:umbrel $UMBREL_APPS_DIR
  fi
fi

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

# Create dashboard integration files if we have permissions
if [ -d "$UMBREL_APPS_DIR" ]; then
  echo "Creating app metadata for Umbrel dashboard..."
  
  # Create app metadata file
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

  # Register app in app-data.json - with sudo if needed
  UMBREL_APP_DATA="$UMBREL_DIR/app-data.json"
  if [ -f "$UMBREL_APP_DATA" ]; then
    echo "Registering app with Umbrel dashboard..."
    if command -v jq > /dev/null; then
      # Create temporary file with updated JSON
      TMP_FILE=$(mktemp)
      jq ".apps += {\"bitcorn-lightning\": {\"id\": \"bitcorn-lightning\", \"name\": \"BitCorn Lightning\", \"icon\": \"/apps/bitcorn-lightning/icon.png\", \"port\": 3001}}" $UMBREL_APP_DATA > $TMP_FILE
      
      # Use sudo to update the actual file if needed
      if [ -w "$UMBREL_APP_DATA" ]; then
        mv $TMP_FILE $UMBREL_APP_DATA
      else
        sudo mv $TMP_FILE $UMBREL_APP_DATA
        sudo chown umbrel:umbrel $UMBREL_APP_DATA
      fi
      
      echo "✓ App registered in dashboard"
    else
      echo "! jq not found - cannot update app-data.json"
      echo "! App icon may not appear in dashboard"
    fi
  fi
else
  echo "! Dashboard integration skipped (permission denied)"
  echo "! App will work but won't appear in the Umbrel dashboard"
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
if [ -d "$UMBREL_APPS_DIR" ]; then
  echo "The app icon should appear in your Umbrel dashboard"
else
  echo "Note: App icon will not appear in dashboard due to permission issues"
  echo "The app is still functional at http://umbrel.local:3001"
fi
echo "================================================================"