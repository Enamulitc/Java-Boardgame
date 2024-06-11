#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update the apt package index
sudo apt-get update

# Install packages needed to use the Kubernetes apt repository
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Create the keyrings directory if it does not exist
if [ ! -d /etc/apt/keyrings ]; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
fi

# Download the public signing key for the Kubernetes package repositories
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # Allow unprivileged APT programs to read this keyring

# Add the Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # Helps tools such as command-not-found to work correctly

# Update apt package index
sudo apt-get update

# Install kubectl
sudo apt-get install -y kubectl

# Verify kubectl installation
if command_exists kubectl; then
    echo "kubectl installed successfully"
else
    echo "kubectl installation failed"
fi
