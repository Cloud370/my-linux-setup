# my-linux-setup

My Linux environment configuration files and scripts.

## Quick Start

```bash
# Clone + interactive install
bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh)

# Clone + install specific modules
bash <(curl -fsSL .../bootstrap.sh) tmux nvm docker

# Clone + install all (with password for encrypted configs)
bash <(curl -fsSL .../bootstrap.sh) -p <password> --all
```

## Usage

```bash
./install.sh                         # Interactive — select from menu
./install.sh bash                    # Install bash aliases
./install.sh tmux                    # Install one module
./install.sh nvm docker              # Install multiple modules
./install.sh --all                   # Install everything
./install.sh -p mypass --all         # Install all, password via CLI
./install.sh --list                  # List available modules
```

## Available Modules

| Module | Description |
|--------|-------------|
| bash   | Manage `~/.bash_aliases` and add a minimal `~/.bashrc` source block for native `ll` |
| tmux   | Tmux configuration (symlink) |
| nvm    | Install nvm + Node.js LTS |
| docker | Install Docker CE + Compose |

## Structure

```
install.sh              # Installer (CLI + interactive)
bootstrap.sh            # curl one-liner entry point
lib/
  utils.sh              # Shared helpers
  crypto.sh             # Encryption helpers
configs/
  bash/setup.sh         # Bash aliases integration
  tmux/setup.sh         # Tmux config
  nvm/setup.sh          # nvm + Node.js
  docker/setup.sh       # Docker CE
```

## Bash Module

The `bash` module keeps shell changes minimal:

- symlinks the managed `configs/bash/.bash_aliases` file to `~/.bash_aliases`
- ensures `~/.bashrc` loads `~/.bash_aliases` with one small managed block
- provides a native `ll` alias based on `ls`, with no `eza`/`exa` dependency

```bash
./install.sh bash
```

## Encrypted Configs

Sensitive files are stored encrypted in git, decrypted with a password at install time.

```bash
# Set a password hint (visible in git)
./install.sh secret hint "favorite color + year"

# Mark a file as secret
./install.sh secret add configs/ssh/config

# Re-encrypt after editing
./install.sh secret encrypt             # interactive
./install.sh -p mypass secret encrypt   # CLI

# Decrypt on a new machine
./install.sh secret decrypt             # interactive
./install.sh -p mypass secret decrypt   # CLI

# Check status
./install.sh secret status
```

In `setup.sh`, use `link_secret` for encrypted files:

```bash
link_secret "$MODULE_DIR/config" "$HOME/.ssh/config"
```

## Adding a Module

Create `configs/<name>/setup.sh`:

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
