#!/bin/bash
set -e

UMBREL_APP_DIR="$HOME/umbrel/app-data/bitcorn-lightning-app"

# Display welcome message
echo "================================================================"
echo "BitCorn Lightning App - Installation Script"
echo "================================================================"
echo ""
echo "This script will install BitCorn Lightning on your Umbrel node."
echo "Before continuing, make sure you have your Supabase API key ready."
echo ""
read -p "Press Enter to continue, or Ctrl+C to cancel..."

# Create app directory
mkdir -p $UMBREL_APP_DIR

# Check if we're running on Umbrel
if [ -f "$HOME/umbrel/scripts/app" ]; then
    echo "✓ Umbrel detected"
    INSTALL_METHOD="umbrel"
else
    echo "! Umbrel scripts not found, using manual installation"
    INSTALL_METHOD="manual"
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

# Install app using Umbrel script if available
if [ "$INSTALL_METHOD" = "umbrel" ]; then
    echo "Installing via Umbrel app system..."
    $HOME/umbrel/scripts/app install bitcorn-lightning
else
    # Manual installation
    echo "Performing manual installation..."
    
    # Clone app repository
    echo "Downloading app files..."
    git clone https://github.com/ethanccail/public-bitcorn-app $UMBREL_APP_DIR/temp
    
    # Copy docker-compose file
    cp $UMBREL_APP_DIR/temp/docker-compose.yml $UMBREL_APP_DIR/docker-compose.yml
    
    # Clean up
    rm -rf $UMBREL_APP_DIR/temp
    
    # Start app
    cd $UMBREL_APP_DIR
    docker compose pull
    docker compose up -d
fi

echo ""
echo "================================================================"
echo "BitCorn Lightning has been installed!"
echo "Access your app at: http://umbrel.local:3001"
echo "================================================================"