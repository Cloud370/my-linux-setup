#!/usr/bin/env bash
# Shared utilities for setup scripts

BACKUP_DIR="$REPO_DIR/.backups/$(date +%Y%m%d_%H%M%S)"

# Colors
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[0;33m'
_BLUE='\033[0;34m'
_CYAN='\033[0;36m'
_BOLD='\033[1m'
_DIM='\033[2m'
_NC='\033[0m'

info()    { echo -e "  ${_BLUE}::${_NC} $*"; }
success() { echo -e "  ${_GREEN}✓${_NC} $*"; }
warn()    { echo -e "  ${_YELLOW}!${_NC} $*"; }
error()   { echo -e "  ${_RED}✗${_NC} $*" >&2; }

# Create a symlink, backing up existing files if needed.
#   link_file <source> <target>
link_file() {
    local src="$1" target="$2"

    # Already correctly linked
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
        success "${_DIM}${target}${_NC} (already linked)"
        return 0
    fi

    # Back up existing file/link
    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
        warn "Backed up existing ${target} → ${_DIM}${BACKUP_DIR}/${_NC}"
    fi

    mkdir -p "$(dirname "$target")"
    ln -sf "$src" "$target"
    success "${target} → ${_DIM}${src}${_NC}"
}

# Copy a file, backing up existing one if needed.
#   copy_file <source> <target>
copy_file() {
    local src="$1" target="$2"

    if [ -e "$target" ] && diff -q "$src" "$target" &>/dev/null; then
        success "${_DIM}${target}${_NC} (already up to date)"
        return 0
    fi

    if [ -e "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$target" "$BACKUP_DIR/$(basename "$target")"
        warn "Backed up existing ${target} → ${_DIM}${BACKUP_DIR}/${_NC}"
    fi

    mkdir -p "$(dirname "$target")"
    cp "$src" "$target"
    success "${target}"
}

# Run a command with logging.
#   run_cmd <description> <command...>
run_cmd() {
    local desc="$1"; shift
    info "$desc"
    if "$@"; then
        success "Done"
    else
        error "Failed: $*"
        return 1
    fi
}
