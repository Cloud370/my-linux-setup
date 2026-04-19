# Description: Tmux terminal multiplexer configuration

link_file "$MODULE_DIR/.tmux.conf" "$HOME/.tmux.conf"

if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
    if tmux source-file "$HOME/.tmux.conf"; then
        success "Reloaded tmux config"
    else
        warn "tmux is running but config reload failed"
    fi
fi
