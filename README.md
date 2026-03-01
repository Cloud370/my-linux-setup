# my-linux-setup

My Linux environment configuration files and scripts.

## Structure

```
install.sh         # Installer (CLI + interactive)
lib/utils.sh       # Shared helper functions
tmux/              # Tmux configuration
  setup.sh         # Module install script
  .tmux.conf
```

## Usage

```bash
git clone https://github.com/Cloud370/my-linux-setup.git ~/my-linux-setup
cd ~/my-linux-setup

# Interactive mode
./install.sh

# Install specific modules
./install.sh tmux zsh

# Install everything
./install.sh --all

# List available modules
./install.sh --list
```

## Adding a new module

1. Create a directory: `mkdir mymodule`
2. Add a `setup.sh` inside it:

```bash
# Description: Short description here

link_file "$MODULE_DIR/.myconfig" "$HOME/.myconfig"
```

3. Put your config files in the same directory.

The installer auto-discovers all directories containing a `setup.sh`.
