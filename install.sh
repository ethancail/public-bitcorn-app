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

# Create app icon in Umbrel's user-data directory
echo "Installing app icon..."
sudo mkdir -p /home/umbrel/umbrel/user-data/app-icons
sudo curl -s -L -o /home/umbrel/umbrel/user-data/app-icons/bitcorn-lightning.png https://raw.githubusercontent.com/ethancail/public-bitcorn-app/main/assets/icon.png
sudo chown umbrel:umbrel /home/umbrel/umbrel/user-data/app-icons/bitcorn-lightning.png

# Register app with Umbrel by creating app definition
echo "Registering app with Umbrel..."
sudo mkdir -p /home/umbrel/umbrel/apps/bitcorn-lightning
sudo tee /home/umbrel/umbrel/apps/bitcorn-lightning/app.yml > /dev/null << 'APPDEF'
id: bitcorn-lightning
name: BitCorn Lightning
tagline: Bitcoin & Lightning for Grain Sales
icon: /user-data/app-icons/bitcorn-lightning.png
port: 3001
path: ""
APPDEF
sudo chown -R umbrel:umbrel /home/umbrel/umbrel/apps/bitcorn-lightning

# Restart Umbrel services to detect the new app
echo "Restarting Umbrel services..."
cd /home/umbrel/umbrel
sudo docker compose restart

echo ""
echo "================================================================"
echo "✅ BitCorn Lightning has been installed successfully!"
echo "================================================================"
echo ""
echo "The app should now appear in your Umbrel dashboard."
echo ""
echo "If you don't see it immediately:"
echo "1. Wait 30 seconds for services to restart"
echo "2. Refresh your browser (Ctrl+Shift+R or Cmd+Shift+R)"
echo "3. Clear your browser cache if needed"
echo ""
echo "Access your app at: http://umbrel.local:3001"
echo "================================================================"