#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/utils.sh"
source "$REPO_DIR/lib/crypto.sh"

# ── Discovery ─────────────────────────────────────────────────

discover_modules() {
    local seen=""
    for f in "$REPO_DIR"/configs/*/setup.sh "$REPO_DIR"/configs/*/setup.sh.enc; do
        [ -f "$f" ] || continue
        local name
        name="$(basename "$(dirname "$f")")"
        case "$seen" in *"|$name|"*) continue ;; esac
        seen="${seen}|$name|"
        echo "$name"
    done
}

get_description() {
    local name="$1"
    local file="$REPO_DIR/configs/$name/setup.sh"
    if [ -f "$file" ]; then
        sed -n 's/^# Description: *//p' "$file" | head -1
    elif [ -f "${file}.enc" ]; then
        echo "[encrypted]"
    fi
}

# ── Install ───────────────────────────────────────────────────

install_item() {
    local name="$1"
    local setup="$REPO_DIR/configs/$name/setup.sh"
    local enc="${setup}.enc"

    if [ ! -f "$setup" ] && [ ! -f "$enc" ]; then
        error "Not found: '${_BOLD}$name${_NC}'"
        error "Run ${_BOLD}./install.sh --list${_NC} to see available items"
        return 1
    fi

    # Decrypt setup.sh if only .enc exists
    if [ ! -f "$setup" ] && [ -f "$enc" ]; then
        local pass
        pass="$(_get_password decrypt)"
        info "Decrypting ${name}/setup.sh ..."
        if ! _decrypt_file "$enc" "$setup" "$pass"; then
            error "Decryption failed — wrong password?"
            _SECRET_PASS=""
            return 1
        fi
    fi

    local desc
    desc="$(get_description "$name")"
    echo ""
    echo -e "  ${_CYAN}▸${_NC} ${_BOLD}${name}${_NC}  ${_DIM}${desc}${_NC}"

    MODULE_DIR="$REPO_DIR/configs/$name"
    source "$setup"
}

# ── Interactive mode ──────────────────────────────────────────

interactive() {
    local items=()
    while IFS= read -r item; do
        items+=("$item")
    done < <(discover_modules)

    if [ ${#items[@]} -eq 0 ]; then
        warn "No modules found"; return
    fi

    echo ""
    echo -e "  ${_BOLD}my-linux-setup${_NC}  ${_DIM}— interactive installer${_NC}"
    echo ""

    for i in "${!items[@]}"; do
        local name="${items[$i]}"
        local desc
        desc="$(get_description "$name")"
        printf "  ${_CYAN}%d)${_NC}  %-15s ${_DIM}%s${_NC}\n" $((i + 1)) "$name" "$desc"
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
    done < <(discover_modules)

    if [ ${#items[@]} -eq 0 ]; then
        warn "No modules found"; return
    fi

    echo ""
    echo -e "  ${_BOLD}Available modules:${_NC}"
    echo ""
    for name in "${items[@]}"; do
        local desc
        desc="$(get_description "$name")"
        printf "    ${_CYAN}%-15s${_NC} %s\n" "$name" "$desc"
    done
    echo ""
}

usage() {
    cat <<EOF

  ${_BOLD}Usage:${_NC}  ./install.sh [options] [name ...]

  ${_BOLD}Options:${_NC}
    -a, --all          Install all modules
    -l, --list         List available modules
    -p, --password P   Provide password for encrypted configs (skip prompt)
    -h, --help         Show this help

  ${_BOLD}Examples:${_NC}
    ./install.sh                          Interactive mode
    ./install.sh tmux                     Install a config module
    ./install.sh nvm docker               Install tools
    ./install.sh -p mypass --all          Install all with password
    ./install.sh secret add <file>        Encrypt a config file
    ./install.sh -p mypass secret decrypt Decrypt all secrets

  ${_BOLD}Remote:${_NC}
    bash <(curl -fsSL https://raw.githubusercontent.com/Cloud370/my-linux-setup/main/bootstrap.sh)
    bash <(curl -fsSL .../bootstrap.sh) nvm docker
    bash <(curl -fsSL .../bootstrap.sh) -p mypass --all

EOF
}

# ── Main ──────────────────────────────────────────────────────

main() {
    # Parse global options
    while [ $# -gt 0 ]; do
        case "$1" in
            -p|--password) _SECRET_PASS="${2:?Password required after -p}"; shift 2 ;;
            *)  break ;;
        esac
    done

    if [ $# -eq 0 ]; then
        interactive
        return
    fi

    case "$1" in
        -h|--help)  usage ;;
        -l|--list)  list_items ;;
        secret)     shift; cmd_secret "$@" ;;
        -a|--all)
            local items=()
            while IFS= read -r item; do
                items+=("$item")
            done < <(discover_modules)
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
