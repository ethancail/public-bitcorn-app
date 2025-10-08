#!/bin/bash
set -e

# Set paths for Umbrel
UMBREL_DIR="/home/umbrel/umbrel"
UMBREL_APP_DIR="$UMBREL_DIR/app-data/bitcorn-lightning-app"
UMBREL_APP_STORE_DIR="$UMBREL_DIR/app-store/bitcorn-lightning"

echo "================================================================"
echo "BitCorn Lightning App - Installation Script"
echo "================================================================"

# Create app data directory
echo "Creating app directories..."
mkdir -p $UMBREL_APP_DIR/data

# Create app store directory for icon and metadata (try with sudo if needed)
if [ ! -d "$UMBREL_APP_STORE_DIR" ]; then
  sudo mkdir -p $UMBREL_APP_STORE_DIR || echo "Could not create app store directory"
  [ -d "$UMBREL_APP_STORE_DIR" ] && sudo chown -R umbrel:umbrel $UMBREL_APP_STORE_DIR
fi

# Prompt for Supabase key
echo "Enter your Supabase API key:"
read -s SUPABASE_KEY
echo "Key received!"

# Create environment file
echo "Creating environment configuration..."
cat > $UMBREL_APP_DIR/.env << EOL
SUPABASE_URL=https://whnijkkttovsozjowkif.supabase.co
SUPABASE_KEY=$SUPABASE_KEY
EOL
chmod 600 $UMBREL_APP_DIR/.env

# Create docker-compose file
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

# Add app metadata for dashboard - check both possible locations
if [ -d "$UMBREL_APP_STORE_DIR" ]; then
  echo "Creating app metadata in app-store directory..."
  cat > $UMBREL_APP_STORE_DIR/umbrel-app.yml << 'EOL'
manifestVersion: 1
id: bitcorn-lightning
category: finance
name: BitCorn Lightning
version: "1.0.0"
tagline: Bitcoin & Lightning for Grain Sales
description: Manage Bitcoin Lightning transactions between grain merchants and farmers
developer: BitCorn Technologies Inc.
website: https://github.com/ethancail/public-bitcorn-app
dependencies:
  - lightning
repo: https://github.com/ethancail/public-bitcorn-app
support: https://github.com/ethancail/public-bitcorn-app/issues
port: 3001
EOL

  # Create app icon placeholder
  sudo touch $UMBREL_APP_STORE_DIR/icon.png
  sudo chown umbrel:umbrel $UMBREL_APP_STORE_DIR/icon.png
  
  # Download icon if curl is available
  if command -v curl &> /dev/null; then
    sudo curl -s -o $UMBREL_APP_STORE_DIR/icon.png https://raw.githubusercontent.com/ethancail/public-bitcorn-app/main/assets/icon.png
    sudo chown umbrel:umbrel $UMBREL_APP_STORE_DIR/icon.png
  fi
fi

# Start the container with sudo
echo "Starting BitCorn Lightning App..."
cd $UMBREL_APP_DIR
sudo docker compose pull
sudo docker compose up -d

echo "================================================================"
echo "BitCorn Lightning has been installed!"
echo "Access your app at: http://umbrel.local:3001"
echo ""
echo "After logging in, run this command to set your node as admin:"
echo "docker compose exec -T api node src/utils/get-node-pubkey.js"
echo "================================================================"