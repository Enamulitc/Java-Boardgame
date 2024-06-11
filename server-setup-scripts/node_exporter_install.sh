#!/bin/bash

echo "Create an Exporter User"
sudo useradd --no-create-home --shell /bin/false node_exporter

echo "Node Expoter Downloading....."
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz

echo "Unzip the newly downloaded file"
tar xvf node_exporter-1.3.1.linux-amd64.tar.gz

echo "Copy node exporter to binary path"
sudo cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin

echo "Change the owner of nodeexporter"
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

service_file="/etc/systemd/system/node_exporter.service"

# Check if the file doesn't exist
if [ ! -f "$service_file" ]; then
    sudo tee "$service_file" > /dev/null <<EOF
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
EOF

    echo "File $service_file created with content."
else
    echo "$service_file already exists. Please remove it first if you want to create a new one."
fi

sudo systemctl daemon-reload
sudo systemctl start node_exporter.service
sudo systemctl status node_exporter.service
sudo systemctl enable node_exporter.service

