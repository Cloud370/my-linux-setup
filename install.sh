#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/utils.sh"

# ── Discovery ─────────────────────────────────────────────────

# Modules: directories containing setup.sh
discover_modules() {
    for setup in "$REPO_DIR"/*/setup.sh; do
        [ -f "$setup" ] || continue
        basename "$(dirname "$setup")"
    done
}

# Scripts: executable .sh files in scripts/
discover_scripts() {
    for script in "$REPO_DIR"/scripts/*.sh; do
        [ -f "$script" ] || continue
        basename "$script" .sh
    done
}

# Unified list: all installable items (modules + scripts)
discover_all() {
    discover_modules
    discover_scripts
}

get_description() {
    local name="$1"
    local file

    if [ -f "$REPO_DIR/$name/setup.sh" ]; then
        file="$REPO_DIR/$name/setup.sh"
    elif [ -f "$REPO_DIR/scripts/$name.sh" ]; then
        file="$REPO_DIR/scripts/$name.sh"
    else
        return
    fi

    sed -n 's/^# Description: *//p' "$file" | head -1
}

get_type() {
    local name="$1"
    if [ -f "$REPO_DIR/$name/setup.sh" ]; then
        echo "module"
    elif [ -f "$REPO_DIR/scripts/$name.sh" ]; then
        echo "script"
    fi
}

# ── Install ───────────────────────────────────────────────────

install_item() {
    local name="$1"
    local type
    type="$(get_type "$name")"

    if [ -z "$type" ]; then
        error "Not found: '${_BOLD}$name${_NC}'"
        error "Run ${_BOLD}./install.sh --list${_NC} to see available items"
        return 1
    fi

    local desc
    desc="$(get_description "$name")"
    echo ""
    echo -e "  ${_CYAN}▸${_NC} ${_BOLD}${name}${_NC}  ${_DIM}${desc}${_NC}"

    case "$type" in
        module)
            MODULE_DIR="$REPO_DIR/$name"
            source "$REPO_DIR/$name/setup.sh"
            ;;
        script)
            bash "$REPO_DIR/scripts/$name.sh"
            ;;
    esac
}

# ── Interactive mode ──────────────────────────────────────────

interactive() {
    local items=()
    while IFS= read -r item; do
        items+=("$item")
    done < <(discover_all)

    if [ ${#items[@]} -eq 0 ]; then
        warn "No modules or scripts found"; return
    fi

    echo ""
    echo -e "  ${_BOLD}my-linux-setup${_NC}  ${_DIM}— interactive installer${_NC}"
    echo ""

    local prev_type=""
    for i in "${!items[@]}"; do
        local name="${items[$i]}"
        local type desc
        type="$(get_type "$name")"
        desc="$(get_description "$name")"

        # Section header when type changes
        if [ "$type" != "$prev_type" ]; then
            [ -n "$prev_type" ] && echo ""
            case "$type" in
                module) echo -e "  ${_DIM}── Modules (config symlinks) ──${_NC}" ;;
                script) echo -e "  ${_DIM}── Scripts (one-off commands) ──${_NC}" ;;
            esac
            prev_type="$type"
        fi

        printf "  ${_CYAN}%d)${_NC}  %-20s ${_DIM}%s${_NC}\n" $((i + 1)) "$name" "$desc"
    done

    echo ""
    printf "  ${_CYAN}a)${_NC}  Install all\n"
    printf "  ${_CYAN}q)${_NC}  Quit\n"
    echo ""

    local selected=()
    read -rp "  Choose (e.g. 1 3, a=all, q=quit): " choices

    case "$choices" in
        q|Q) return ;;
        a|A) selected=("${items[@]}") ;;
        *)
            for c in $choices; do
                if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le ${#items[@]} ]; then
                    selected+=("${items[$((c - 1))]}")
                else
                    warn "Skipping invalid choice: $c"
                fi
            done
            ;;
    esac

    if [ ${#selected[@]} -eq 0 ]; then
        warn "Nothing selected"; return
    fi

    for item in "${selected[@]}"; do
        install_item "$item"
    done

    echo ""
    success "All done!"
}

# ── CLI helpers ───────────────────────────────────────────────

list_items() {
    local items=()
    while IFS= read -r item; do
        items+=("$item")
    done < <(discover_all)

    if [ ${#items[@]} -eq 0 ]; then
        warn "No modules or scripts found"; return
    fi

    local prev_type=""
    for name in "${items[@]}"; do
        local type desc
        type="$(get_type "$name")"
        desc="$(get_description "$name")"

        if [ "$type" != "$prev_type" ]; then
            echo ""
            case "$type" in
                module) echo -e "  ${_BOLD}Modules${_NC}  ${_DIM}(config symlinks)${_NC}" ;;
                script) echo -e "  ${_BOLD}Scripts${_NC}  ${_DIM}(standalone, also curl-able)${_NC}" ;;
            esac
            prev_type="$type"
        fi

        printf "    ${_CYAN}%-20s${_NC} %s\n" "$name" "$desc"
    done
    echo ""
}

usage() {
    cat <<EOF

  ${_BOLD}Usage:${_NC}  ./install.sh [options] [name ...]

  ${_BOLD}Options:${_NC}
    -a, --all     Install all modules and scripts
    -l, --list    List available modules and scripts
    -h, --help    Show this help

  ${_BOLD}Examples:${_NC}
    ./install.sh                   Interactive mode
    ./install.sh tmux              Install a module
    ./install.sh example-install-docker   Run a script
    ./install.sh --all             Install everything

  ${_BOLD}Remote (curl):${_NC}
    bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh)
    bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh) --all
    bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/scripts/xxx.sh)

EOF
}

# ── Main ──────────────────────────────────────────────────────

main() {
    if [ $# -eq 0 ]; then
        interactive
        return
    fi

    case "$1" in
        -h|--help)  usage ;;
        -l|--list)  list_items ;;
        -a|--all)
            local items=()
            while IFS= read -r item; do
                items+=("$item")
            done < <(discover_all)
            for item in "${items[@]}"; do
                install_item "$item"
            done
            echo ""
            success "All done!"
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            for item in "$@"; do
                install_item "$item"
            done
            echo ""
            success "All done!"
            ;;
    esac
}

main "$@"
