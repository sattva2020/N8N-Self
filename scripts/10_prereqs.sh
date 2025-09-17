#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "[+] Installing Docker Engine..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release git openssl
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  if id -nG "$USER" | grep -qvw docker; then
    sudo usermod -aG docker "$USER" || true
    echo "[i] Added $USER to docker group. You must log out and log back in (or run 'newgrp docker') for this to take effect."
  fi
fi

sudo apt-get install -y apache2-utils jq

if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 80/tcp || true
  sudo ufw allow 443/tcp || true
fi

echo "[OK] Prerequisites installed."
