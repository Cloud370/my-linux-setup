#!/usr/bin/env bash
# Description: Install nvm and Node.js LTS
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/scripts/install-nvm.sh)
#
# Environment variables:
#   NODE_VERSION  Node.js version to install (default: --lts)
#   NVM_VERSION   nvm version to install     (default: v0.40.4)
set -euo pipefail

NVM_VERSION="${NVM_VERSION:-v0.40.4}"
NODE_VERSION="${NODE_VERSION:-}"

echo ""
echo "  :: Installing nvm ${NVM_VERSION} ..."
echo ""

# Install nvm
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# Load nvm into current shell
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node.js
if [ -n "$NODE_VERSION" ]; then
    echo ""
    echo "  :: Installing Node.js ${NODE_VERSION} ..."
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
else
    echo ""
    echo "  :: Installing Node.js LTS ..."
    nvm install --lts
    nvm alias default lts/*
fi

echo ""
echo "  ✓ nvm $(nvm --version)"
echo "  ✓ node $(node --version)"
echo "  ✓ npm $(npm --version)"
echo ""
