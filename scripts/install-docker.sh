#!/usr/bin/env bash
# Description: Install Docker CE and Docker Compose
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/scripts/install-docker.sh)
#
# What this script does:
#   1. Install Docker CE via official get.docker.com script
#   2. Add current user to docker group (no sudo needed after re-login)
#   3. Enable and start dockerd
set -euo pipefail

echo ""
echo "  :: Installing Docker CE ..."
echo ""

# Check if docker is already installed
if command -v docker &>/dev/null; then
    echo "  ! Docker is already installed: $(docker --version)"
    read -rp "  Reinstall? [y/N] " ans < /dev/tty
    case "$ans" in
        y|Y) ;;
        *)   echo "  Skipped."; exit 0 ;;
    esac
fi

# Install via official script
curl -fsSL https://get.docker.com | sudo sh

# Add current user to docker group
if ! groups "$USER" | grep -q '\bdocker\b'; then
    echo ""
    echo "  :: Adding $USER to docker group ..."
    sudo usermod -aG docker "$USER"
    echo "  ! Log out and back in, or run: newgrp docker"
fi

# Enable and start
if command -v systemctl &>/dev/null; then
    sudo systemctl enable --now docker
fi

echo ""
echo "  ✓ $(docker --version)"
if command -v docker compose &>/dev/null; then
    echo "  ✓ Docker Compose $(docker compose version --short 2>/dev/null || echo 'installed')"
fi
echo ""
