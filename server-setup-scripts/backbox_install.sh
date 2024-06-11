#!/bin/bash

# Define variables
BLACKBOX_VERSION="0.24.0"
BLACKBOX_TAR="blackbox_exporter-$BLACKBOX_VERSION.linux-amd64.tar.gz"
BLACKBOX_URL="https://github.com/prometheus/blackbox_exporter/releases/download/v$BLACKBOX_VERSION/$BLACKBOX_TAR"
BLACKBOX_DIR="blackbox_exporter-$BLACKBOX_VERSION.linux-amd64"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/blackbox"
SERVICE_FILE="/lib/systemd/system/blackbox.service"

# Download the Blackbox Exporter
wget $BLACKBOX_URL

# Untar the newly downloaded file
tar -xvf $BLACKBOX_TAR

# Navigate to the extracted directory
cd $BLACKBOX_DIR

# Create the configuration directory
sudo mkdir -p $CONFIG_DIR

# Copy the files to the desired directories
sudo cp -r blackbox_exporter $INSTALL_DIR
sudo cp -r blackbox.yml $CONFIG_DIR

# Create a user for Blackbox
sudo useradd --no-create-home --shell /bin/false blackbox

# Change ownership of the files
sudo chown -R blackbox:blackbox $INSTALL_DIR/blackbox_exporter
sudo chown -R blackbox:blackbox $CONFIG_DIR/*

# Prepare the Blackbox YML file
cat <<EOL | sudo tee $CONFIG_DIR/blackbox.yml
modules:
  http_2xx_example:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []  # Defaults to 2xx
      method: GET
EOL

# Create a Blackbox system service file
cat <<EOL | sudo tee $SERVICE_FILE
[Unit]
Description=Blackbox Exporter Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=blackbox
Group=blackbox
ExecStart=$INSTALL_DIR/blackbox_exporter \\
  --config.file=$CONFIG_DIR/blackbox.yml \\
  --web.listen-address=":9115"

Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable the newly created Blackbox service
sudo systemctl enable blackbox.service

# Start the service
sudo systemctl start blackbox.service

# Check the status of the service
sudo systemctl status blackbox.service

