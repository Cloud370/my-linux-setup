# Description: Install nvm and Node.js LTS
# Environment variables:
#   NODE_VERSION  Specific version to install (default: LTS)
#   NVM_VERSION   nvm release tag             (default: v0.40.4)

NVM_VERSION="${NVM_VERSION:-v0.40.4}"
NODE_VERSION="${NODE_VERSION:-}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Install nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
    success "nvm already installed ($(. "$NVM_DIR/nvm.sh" && nvm --version))"
else
    info "Installing nvm ${NVM_VERSION} ..."
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    success "nvm installed"
fi

# Load nvm into current shell
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node.js
if [ -n "$NODE_VERSION" ]; then
    info "Installing Node.js ${NODE_VERSION} ..."
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
else
    info "Installing Node.js LTS ..."
    nvm install --lts
    nvm alias default lts/*
fi

success "node $(node --version) / npm $(npm --version)"
