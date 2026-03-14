# Description: Bash aliases with native ls-based ll

BASH_ALIASES_SOURCE="$MODULE_DIR/.bash_aliases"
BASH_ALIASES_TARGET="$HOME/.bash_aliases"
BASHRC_TARGET="$HOME/.bashrc"

MANAGED_START="# >>> my-linux-setup bash aliases >>>"
MANAGED_END="# <<< my-linux-setup bash aliases <<<"
MANAGED_BLOCK_LINES=(
    "$MANAGED_START"
    'if [ -f "$HOME/.bash_aliases" ]; then'
    '    . "$HOME/.bash_aliases"'
    'fi'
    "$MANAGED_END"
)
SINGLE_LINE_SOURCE_BLOCKS=(
    '[ -f ~/.bash_aliases ] && . ~/.bash_aliases'
    '[ -f ~/.bash_aliases ] && source ~/.bash_aliases'
    '[ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"'
    '[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"'
    '. ~/.bash_aliases'
    'source ~/.bash_aliases'
    '. "$HOME/.bash_aliases"'
    'source "$HOME/.bash_aliases"'
)

is_single_line_source_block() {
    local candidate="$1"
    local block

    for block in "${SINGLE_LINE_SOURCE_BLOCKS[@]}"; do
        if [ "$candidate" = "$block" ]; then
            return 0
        fi
    done

    return 1
}

write_bashrc_lines() {
    printf '%s\n' "${updated_lines[@]}" > "$BASHRC_TARGET"
}

append_managed_block() {
    if [ ${#updated_lines[@]} -gt 0 ] && [ -n "${updated_lines[$(( ${#updated_lines[@]} - 1 ))]}" ]; then
        updated_lines+=("")
    fi

    updated_lines+=("${MANAGED_BLOCK_LINES[@]}")
}

ensure_bash_aliases_loaded() {
    local lines=()
    local line
    local replaced=0
    local i

    updated_lines=()

    if [ ! -f "$BASHRC_TARGET" ]; then
        updated_lines=("${MANAGED_BLOCK_LINES[@]}")
        write_bashrc_lines
        success "$BASHRC_TARGET (created with managed ~/.bash_aliases source block)"
        return 0
    fi

    mapfile -t lines < "$BASHRC_TARGET"

    for line in "${lines[@]}"; do
        if [ "$line" = "$MANAGED_START" ]; then
            success "${_DIM}${BASHRC_TARGET}${_NC} (managed ~/.bash_aliases source block already present)"
            return 0
        fi
    done

    for ((i = 0; i < ${#lines[@]}; i++)); do
        line="${lines[$i]}"

        if [ "$line" = 'if [ -f ~/.bash_aliases ]; then' ] \
            && [ $((i + 2)) -lt ${#lines[@]} ] \
            && [ "${lines[$((i + 1))]}" = '    . ~/.bash_aliases' ] \
            && [ "${lines[$((i + 2))]}" = 'fi' ]; then
            updated_lines+=("${MANAGED_BLOCK_LINES[@]}")
            i=$((i + 2))
            replaced=1
            continue
        fi

        if is_single_line_source_block "$line"; then
            updated_lines+=("${MANAGED_BLOCK_LINES[@]}")
            replaced=1
            continue
        fi

        updated_lines+=("$line")
    done

    if [ "$replaced" -eq 1 ]; then
        write_bashrc_lines
        success "$BASHRC_TARGET (replaced existing ~/.bash_aliases source block)"
        return 0
    fi

    if grep -Eq "^[[:space:]]*(\\.|source)[[:space:]]+.*\\.bash_aliases([[:space:]]|[\"']|$)" "$BASHRC_TARGET"; then
        success "${_DIM}${BASHRC_TARGET}${_NC} (already loads ~/.bash_aliases)"
        return 0
    fi

    append_managed_block
    write_bashrc_lines
    success "$BASHRC_TARGET (added managed ~/.bash_aliases source block)"
}

link_file "$BASH_ALIASES_SOURCE" "$BASH_ALIASES_TARGET"
ensure_bash_aliases_loaded
