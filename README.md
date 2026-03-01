# my-linux-setup

My Linux environment configuration files and scripts.

## Quick Start

```bash
# One-liner: clone + interactive install
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh)

# One-liner: clone + install specific modules
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh) tmux

# One-liner: clone + install all
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh) --all

# Run a standalone script directly (no clone needed)
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/scripts/example-install-docker.sh)
```

## Local Usage

```bash
git clone https://github.com/Cloud370/my-linux-setup.git ~/my-linux-setup
cd ~/my-linux-setup

./install.sh              # Interactive mode
./install.sh tmux         # Install specific module
./install.sh --all        # Install everything
./install.sh --list       # List available modules & scripts
```

## Structure

```
bootstrap.sh        # curl one-liner entry point
install.sh          # Installer (CLI + interactive)
lib/utils.sh        # Shared helper functions
tmux/               # [Module] tmux config
  setup.sh
  .tmux.conf
scripts/            # [Scripts] standalone, also curl-able
  example-install-docker.sh
```

## Adding a Module

Modules manage config files via symlinks. Create a directory with a `setup.sh`:

```bash
mkdir zsh
cat > zsh/setup.sh <<'EOF'
# Description: Zsh shell configuration

link_file "$MODULE_DIR/.zshrc" "$HOME/.zshrc"
EOF
```

Available helpers in `setup.sh` (from `lib/utils.sh`):
- `link_file <src> <target>` — symlink with auto-backup
- `copy_file <src> <target>` — copy with auto-backup
- `run_cmd <desc> <command...>` — run and log a command

## Adding a Script

Scripts are standalone and can be curl'd directly. Add a `.sh` file to `scripts/`:

```bash
cat > scripts/install-something.sh <<'EOF'
#!/usr/bin/env bash
# Description: Install something useful
set -euo pipefail

echo "Installing..."
EOF
```

Both modules and scripts are auto-discovered by `install.sh`.
