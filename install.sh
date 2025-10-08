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

# Create app store directory with proper permissions
echo "Setting up app store directory..."
sudo mkdir -p $UMBREL_APP_STORE_DIR
sudo chown -R umbrel:umbrel $UMBREL_APP_STORE_DIR

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

# Create umbrel-app.yml in app-store directory
echo "Creating app metadata..."
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

# Download and set app icon
echo "Downloading app icon..."
sudo curl -s -L -o $UMBREL_APP_STORE_DIR/icon.svg https://raw.githubusercontent.com/ethancail/public-bitcorn-app/main/assets/icon.png
sudo chown umbrel:umbrel $UMBREL_APP_STORE_DIR/icon.svg

# Copy docker-compose to app-store directory as well (Umbrel may look here)
sudo cp $UMBREL_APP_DIR/docker-compose.yml $UMBREL_APP_STORE_DIR/docker-compose.yml
sudo chown umbrel:umbrel $UMBREL_APP_STORE_DIR/docker-compose.yml

# Start the container
echo "Starting BitCorn Lightning App..."
cd $UMBREL_APP_DIR
sudo docker compose pull
sudo docker compose up -d

# Try to restart Umbrel's manager to detect the new app
echo "Notifying Umbrel of new app installation..."
if sudo docker ps | grep -q umbrel_manager; then
  echo "Restarting Umbrel manager..."
  sudo docker restart umbrel_manager_1 2>/dev/null || sudo docker restart $(sudo docker ps --filter name=manager --format "{{.Names}}") 2>/dev/null || echo "Could not restart manager"
fi

echo ""
echo "================================================================"
echo "BitCorn Lightning has been installed!"
echo ""
echo "Access your app at: http://umbrel.local:3001"
echo ""
echo "If the app icon doesn't appear in your Umbrel dashboard:"
echo "1. Try refreshing your browser (Ctrl+Shift+R)"
echo "2. Restart Umbrel: cd ~/umbrel && sudo docker compose restart"
echo "3. The app is still fully functional at the URL above"
echo ""
echo "After logging in, run this command to set your node as admin:"
echo "  cd ~/umbrel/app-data/bitcorn-lightning-app"
echo "  docker compose exec api node src/utils/get-node-pubkey.js"
echo "================================================================"