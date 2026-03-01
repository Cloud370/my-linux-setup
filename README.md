# my-linux-setup

My Linux environment configuration files and scripts.

## Quick Start

```bash
# Clone + interactive install
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh)

# Clone + install all
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh) --all

# Clone + install all (with password for encrypted configs)
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh) -p <password> --all
```

## Local Usage

```bash
./install.sh                    # Interactive mode (prompts for password if needed)
./install.sh tmux               # Install specific module
./install.sh --all              # Install everything
./install.sh -p mypass --all    # Install everything, password via CLI
./install.sh --list             # List available modules & scripts
```

## Standalone Scripts (curl directly)

```bash
# Install nvm + Node.js LTS
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/scripts/install-nvm.sh)

# Install Docker CE + Compose
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/scripts/install-docker.sh)
```

## Structure

```
install.sh                      # Installer (CLI + interactive)
bootstrap.sh                    # curl one-liner entry point
lib/
  utils.sh                      # Shared helpers
  crypto.sh                     # Encryption helpers
configs/                        # Modules — config files
  tmux/
    setup.sh                    # link_file / link_secret calls
    .tmux.conf
scripts/                        # Standalone scripts
  install-nvm.sh                # nvm + Node.js
  install-docker.sh             # Docker CE
```

## Encrypted Configs (Password)

Some config files contain sensitive data. They are stored encrypted in git
and decrypted at install time with a password. No keys — just a simple password.

### Setup (on your main machine)

```bash
# 1. Set a password hint (committed to git, visible to anyone)
./install.sh secret hint "favorite color + birth year"

# 2. Mark files as secret — encrypts them, gitignores the plaintext
./install.sh secret add configs/ssh/config
./install.sh secret add configs/git/.gitconfig-private

# 3. Commit (only .enc files go into git)
git add -A && git commit -m "add encrypted configs"
```

### Decrypt (on a new machine)

```bash
# Interactive — shows hint, prompts for password
./install.sh secret decrypt

# Or via CLI flag — no prompt
./install.sh -p mypass secret decrypt
```

### Re-encrypt after editing

```bash
# After editing a plaintext secret file, re-encrypt before committing
./install.sh secret encrypt           # interactive
./install.sh -p mypass secret encrypt  # CLI
```

### In setup.sh

Use `link_secret` instead of `link_file` for encrypted files:

```bash
# Description: SSH configuration

link_secret "$MODULE_DIR/config" "$HOME/.ssh/config"
```

`link_secret` automatically decrypts the `.enc` file if the plaintext
doesn't exist, then creates the symlink.

### Other secret commands

```bash
./install.sh secret status    # Show encrypt/decrypt status of all secrets
./install.sh secret hint      # Show current hint
```

## Adding a Module

Create a directory under `configs/` with a `setup.sh`:

```bash
mkdir configs/zsh
cat > configs/zsh/setup.sh <<'EOF'
# Description: Zsh shell configuration

link_file "$MODULE_DIR/.zshrc" "$HOME/.zshrc"
EOF
```

Available helpers:
- `link_file <src> <target>` — symlink with auto-backup
- `link_secret <src> <target>` — decrypt + symlink
- `copy_file <src> <target>` — copy with auto-backup
- `run_cmd <desc> <cmd...>` — run and log a command

## Adding a Script

Add a `.sh` file to `scripts/`:

```bash
cat > scripts/install-something.sh <<'EOF'
#!/usr/bin/env bash
# Description: Install something useful
set -euo pipefail

echo "Installing..."
EOF
```

Scripts are auto-discovered by `./install.sh` and can also be curl'd standalone.
