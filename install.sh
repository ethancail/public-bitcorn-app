#!/bin/bash
set -e

# Set paths for Umbrel
UMBREL_DIR="/home/umbrel/umbrel"
UMBREL_APP_DIR="$UMBREL_DIR/app-data/bitcorn-lightning-app"

echo "================================================================"
echo "BitCorn Lightning App - Installation Script"
echo "================================================================"

# Create app data directory
echo "Creating app directories..."
mkdir -p $UMBREL_APP_DIR/data

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

# Create docker-compose file with labels for Umbrel UI
echo "Creating Docker configuration with Umbrel labels..."
cat > $UMBREL_APP_DIR/docker-compose.yml << 'EOL'
version: "3.7"

services:
  api:
    image: ethanccail/lightning-app:latest
    restart: unless-stopped
    container_name: bitcorn_api_1
    labels:
      com.umbrel.app.id: bitcorn-lightning
      com.umbrel.app.name: BitCorn Lightning
      com.umbrel.app.port: "3001"
      com.umbrel.app.category: finance
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

# Start the container
echo "Starting BitCorn Lightning App..."
cd $UMBREL_APP_DIR
sudo docker compose pull
sudo docker compose up -d

# Create app metadata directory and files
echo "Creating app metadata for Umbrel dashboard..."
sudo mkdir -p /home/umbrel/umbrel/apps/bitcorn-lightning

# Download and install app icon
echo "Installing app icon..."
sudo curl -s -L -o /home/umbrel/umbrel/apps/bitcorn-lightning/icon.png https://raw.githubusercontent.com/ethancail/public-bitcorn-app/main/assets/icon.png 2>/dev/null || echo "Warning: Could not download icon"

# Create app.yml manifest
sudo tee /home/umbrel/umbrel/apps/bitcorn-lightning/app.yml > /dev/null << 'APPDEF'
id: bitcorn-lightning
name: BitCorn Lightning
version: "1.0.0"
tagline: Bitcoin & Lightning for Grain Sales
description: Manage Bitcoin Lightning transactions between grain merchants and farmers
category: finance
port: 3001
path: ""
APPDEF

# Set proper ownership
sudo chown -R umbrel:umbrel /home/umbrel/umbrel/apps/bitcorn-lightning

# Try to restart Umbrel manager container to detect new app
echo "Notifying Umbrel of new app..."
MANAGER_CONTAINER=$(sudo docker ps --filter "name=manager" --format "{{.Names}}" | head -n 1)
if [ ! -z "$MANAGER_CONTAINER" ]; then
  echo "Restarting Umbrel manager container: $MANAGER_CONTAINER"
  sudo docker restart $MANAGER_CONTAINER 2>/dev/null || echo "Could not restart manager"
else
  echo "Umbrel manager container not found - dashboard icon may not appear"
fi

echo ""
echo "================================================================"
echo "✅ BitCorn Lightning has been installed successfully!"
echo "================================================================"
echo ""
echo "📱 ACCESS YOUR APP:"
echo "   http://umbrel.local:3001"
echo "   or"
echo "   http://$(hostname -I | awk '{print $1}'):3001"
echo ""
echo "🔍 DASHBOARD ICON:"
echo "   The app should appear in your Umbrel dashboard."
echo "   If it doesn't show immediately:"
echo "   1. Wait 30-60 seconds for Umbrel to detect the app"
echo "   2. Refresh your browser (Ctrl+Shift+R)"
echo "   3. Clear browser cache if needed"
echo ""
echo "💡 The app is fully functional at the URL above even if"
echo "   the dashboard icon doesn't appear immediately."
echo "================================================================"