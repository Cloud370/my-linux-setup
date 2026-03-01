# Description: Install Docker CE and Docker Compose

# Skip if already installed
if command -v docker &>/dev/null; then
    success "Docker already installed ($(docker --version))"
    return 0
fi

# Install via official script
info "Installing Docker CE ..."
curl -fsSL https://get.docker.com | sudo sh

# Add current user to docker group
if ! groups "$USER" | grep -q '\bdocker\b'; then
    info "Adding $USER to docker group ..."
    sudo usermod -aG docker "$USER"
    warn "Log out and back in, or run: newgrp docker"
fi

# Enable and start
if command -v systemctl &>/dev/null; then
    sudo systemctl enable --now docker
fi

success "$(docker --version)"
