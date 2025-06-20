#!/bin/bash

# Script installs Docker, Docker Compose, Python, and Django

echo "Starting development tools installation..."

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if command_exists docker; then
    echo "Docker is already installed."
else
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    echo "Docker installed. Log out and back in to use it without sudo."
fi

if command_exists docker-compose; then
    echo "Docker Compose is already installed."
else
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed."
fi

if command_exists python3; then
    echo "Python 3 is already installed."
else
    echo "Installing Python 3..."
    sudo apt-get update
    sudo apt-get install -y python3
    echo "Python 3 installed."
fi

if python3 -c "import django" >/dev/null 2>&1; then
    echo "Django is already installed."
else
    echo "Installing Django..."
    sudo apt-get install -y python3-django
    echo "Django installed."
fi

echo "Installation complete!"
