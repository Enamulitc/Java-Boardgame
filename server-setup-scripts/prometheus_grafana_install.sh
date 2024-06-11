#!/bin/bash

# Define variables
PROMETHEUS_VERSION="2.34.0-rc.1"
NODE_EXPORTER_VERSION="1.3.1"
GRAFANA_VERSION="8.4.3"
PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
GRAFANA_URL="https://dl.grafana.com/oss/release/grafana_$GRAFANA_VERSION_amd64.deb"

# Update and upgrade system
sudo apt-get update && sudo apt-get upgrade -y

# Create users for Prometheus and Node Exporter
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo useradd --no-create-home --shell /bin/false node_exporter

# Create necessary directories
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# Set ownership of directories
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Download and install Node Exporter
wget $NODE_EXPORTER_URL
tar xvf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
sudo cp node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64*

# Create Node Exporter systemd service
cat <<EOL | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and start Node Exporter service
sudo systemctl daemon-reload
sudo systemctl start node_exporter.service
sudo systemctl enable node_exporter.service
sudo systemctl status node_exporter.service

# Download and install Prometheus
wget $PROMETHEUS_URL
tar xfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64/
sudo cp prometheus promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
sudo cp -r consoles console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus/consoles /etc/prometheus/console_libraries
cd .. && rm -rf prometheus-$PROMETHEUS_VERSION.linux-amd64*

# Create Prometheus configuration file
cat <<EOL | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

rule_files:
  # - "first.rules"
  # - "second.rules"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
EOL

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create Prometheus systemd service
cat <<EOL | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file /etc/prometheus/prometheus.yml \\
  --storage.tsdb.path /var/lib/prometheus/ \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and start Prometheus service
sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus.service
sudo systemctl status prometheus.service

# Install Grafana
sudo apt-get install -y adduser libfontconfig1
wget $GRAFANA_URL
sudo dpkg -i grafana_$GRAFANA_VERSION_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable grafana-server.service
sudo systemctl start grafana-server.service
sudo systemctl status grafana-server.service

# Print completion message
echo "Prometheus, Node Exporter, and Grafana installation and configuration completed."
echo "Prometheus is running on http://localhost:9090"
echo "Grafana is running on http://localhost:3000 (default user and password: admin/admin)"

