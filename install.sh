#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/utils.sh"

# ── Module discovery ──────────────────────────────────────────

discover_modules() {
    local modules=()
    for setup in "$REPO_DIR"/*/setup.sh; do
        [ -f "$setup" ] || continue
        modules+=("$(basename "$(dirname "$setup")")")
    done
    printf '%s\n' "${modules[@]}"
}

get_description() {
    local module="$1"
    grep '^# Description:' "$REPO_DIR/$module/setup.sh" 2>/dev/null \
        | head -1 | sed 's/^# Description: *//'
}

# ── Install ───────────────────────────────────────────────────

install_module() {
    local module="$1"
    local setup="$REPO_DIR/$module/setup.sh"

    if [ ! -f "$setup" ]; then
        error "Module '${_BOLD}$module${_NC}' not found"
        return 1
    fi

    local desc
    desc="$(get_description "$module")"
    echo ""
    echo -e "  ${_CYAN}▸${_NC} ${_BOLD}${module}${_NC}  ${_DIM}${desc}${_NC}"

    MODULE_DIR="$REPO_DIR/$module"
    source "$setup"
}

# ── Interactive mode ──────────────────────────────────────────

interactive() {
    local modules=()
    while IFS= read -r mod; do
        modules+=("$mod")
    done < <(discover_modules)

    if [ ${#modules[@]} -eq 0 ]; then
        warn "No modules found"; return
    fi

    echo ""
    echo -e "  ${_BOLD}my-linux-setup${_NC}  ${_DIM}— interactive installer${_NC}"
    echo ""

    for i in "${!modules[@]}"; do
        local mod="${modules[$i]}"
        local desc
        desc="$(get_description "$mod")"
        printf "  ${_CYAN}%d)${_NC}  %-15s ${_DIM}%s${_NC}\n" $((i + 1)) "$mod" "$desc"
    done

    echo ""
    printf "  ${_CYAN}a)${_NC}  Install all\n"
    printf "  ${_CYAN}q)${_NC}  Quit\n"
    echo ""

    local selected=()
    read -rp "  Choose modules (e.g. 1 3, a=all, q=quit): " choices

    case "$choices" in
        q|Q) return ;;
        a|A) selected=("${modules[@]}") ;;
        *)
            for c in $choices; do
                if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le ${#modules[@]} ]; then
                    selected+=("${modules[$((c - 1))]}")
                else
                    warn "Skipping invalid choice: $c"
                fi
            done
            ;;
    esac

    if [ ${#selected[@]} -eq 0 ]; then
        warn "Nothing selected"; return
    fi

    for mod in "${selected[@]}"; do
        install_module "$mod"
    done

    echo ""
    success "All done!"
}

# ── CLI helpers ───────────────────────────────────────────────

list_modules() {
    local modules=()
    while IFS= read -r mod; do
        modules+=("$mod")
    done < <(discover_modules)

    if [ ${#modules[@]} -eq 0 ]; then
        warn "No modules found"; return
    fi

    echo ""
    echo -e "  ${_BOLD}Available modules:${_NC}"
    echo ""
    for mod in "${modules[@]}"; do
        local desc
        desc="$(get_description "$mod")"
        printf "  ${_CYAN}%-15s${_NC} %s\n" "$mod" "$desc"
    done
    echo ""
}

usage() {
    cat <<EOF

  ${_BOLD}Usage:${_NC}  ./install.sh [options] [module ...]

  ${_BOLD}Options:${_NC}
    -a, --all     Install all modules
    -l, --list    List available modules
    -h, --help    Show this help

  ${_BOLD}Examples:${_NC}
    ./install.sh              Interactive mode
    ./install.sh tmux zsh     Install specific modules
    ./install.sh --all        Install everything

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
        -l|--list)  list_modules ;;
        -a|--all)
            local modules=()
            while IFS= read -r mod; do
                modules+=("$mod")
            done < <(discover_modules)
            for mod in "${modules[@]}"; do
                install_module "$mod"
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
            for mod in "$@"; do
                install_module "$mod"
            done
            echo ""
            success "All done!"
            ;;
    esac
}

main "$@"
