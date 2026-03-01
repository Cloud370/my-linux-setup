#!/usr/bin/env bash
# One-liner entry point:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh) tmux
#   bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh) --all
#
# Environment variables:
#   INSTALL_DIR   Where to clone the repo (default: ~/my-linux-setup)
set -euo pipefail

REPO_URL="https://github.com/Cloud370/my-linux-setup.git"
INSTALL_DIR="${INSTALL_DIR:-$HOME/my-linux-setup}"

# Colors
_GREEN='\033[0;32m' _CYAN='\033[0;36m' _BOLD='\033[1m' _DIM='\033[2m' _NC='\033[0m'

echo ""
echo -e "  ${_BOLD}my-linux-setup${_NC}  ${_DIM}— bootstrap${_NC}"
echo ""

# ── Clone or update ───────────────────────────────────────────

if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "  ${_CYAN}::${_NC} Updating ${_DIM}${INSTALL_DIR}${_NC} ..."
    git -C "$INSTALL_DIR" pull --ff-only --quiet
else
    echo -e "  ${_CYAN}::${_NC} Cloning into ${_DIM}${INSTALL_DIR}${_NC} ..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

echo -e "  ${_GREEN}✓${_NC} Repository ready"
echo ""

# ── Hand off to install.sh ────────────────────────────────────

exec bash "$INSTALL_DIR/install.sh" "$@"
