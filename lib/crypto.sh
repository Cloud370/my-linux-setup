#!/usr/bin/env bash
# Encryption utilities for secret config files
# Uses openssl aes-256-cbc, auto-detects pbkdf2 support

SECRETFILES="$REPO_DIR/.secretfiles"
SECRET_HINT_FILE="$REPO_DIR/.secret-hint"
_SECRET_PASS=""

# ── Cipher detection ──────────────────────────────────────────

_init_cipher() {
    if openssl enc -aes-256-cbc -pbkdf2 -nosalt -pass pass:x < /dev/null > /dev/null 2>&1; then
        _CIPHER_ARGS=(-aes-256-cbc -salt -pbkdf2 -iter 100000)
    else
        _CIPHER_ARGS=(-aes-256-cbc -salt -md sha256)
    fi
}
_init_cipher

# ── Core ──────────────────────────────────────────────────────

_encrypt_file() {
    local src="$1" dst="$2" pass="$3"
    _SECRET_PASS_ENV="$pass" openssl enc "${_CIPHER_ARGS[@]}" \
        -a -pass env:_SECRET_PASS_ENV -in "$src" -out "$dst"
}

_decrypt_file() {
    local src="$1" dst="$2" pass="$3"
    _SECRET_PASS_ENV="$pass" openssl enc "${_CIPHER_ARGS[@]}" \
        -a -d -pass env:_SECRET_PASS_ENV -in "$src" -out "$dst"
}

# ── Password prompt ──────────────────────────────────────────

_show_hint() {
    if [ -f "$SECRET_HINT_FILE" ]; then
        echo -e "  ${_DIM}Hint: $(cat "$SECRET_HINT_FILE")${_NC}" >&2
    fi
}

_prompt_password() {
    local mode="${1:-decrypt}"
    _show_hint
    local pass
    read -rsp "  Enter password: " pass < /dev/tty
    echo "" >&2
    if [ -z "$pass" ]; then
        error "Password cannot be empty"
        return 1
    fi
    if [ "$mode" = "encrypt" ]; then
        local pass2
        read -rsp "  Confirm password: " pass2 < /dev/tty
        echo "" >&2
        if [ "$pass" != "$pass2" ]; then
            error "Passwords do not match"
            return 1
        fi
    fi
    printf '%s' "$pass"
}

_get_password() {
    local mode="${1:-decrypt}"
    if [ -n "$_SECRET_PASS" ]; then
        printf '%s' "$_SECRET_PASS"
        return
    fi
    _SECRET_PASS="$(_prompt_password "$mode")"
    printf '%s' "$_SECRET_PASS"
}

# ── Secret file list helpers ─────────────────────────────────

_list_secrets() {
    [ -f "$SECRETFILES" ] || return
    grep -v '^#' "$SECRETFILES" | grep -v '^[[:space:]]*$' || true
}

_is_secret() {
    [ -f "$SECRETFILES" ] && grep -qxF "$1" "$SECRETFILES"
}

# ── link_secret (used in setup.sh) ───────────────────────────
# Like link_file, but auto-decrypts <src>.enc → <src> first.
#   link_secret <src> <target>

link_secret() {
    local src="$1" target="$2"
    local enc_file="${src}.enc"

    if [ ! -f "$src" ] && [ -f "$enc_file" ]; then
        local pass
        pass="$(_get_password decrypt)"
        info "Decrypting $(basename "$src") ..."
        if ! _decrypt_file "$enc_file" "$src" "$pass"; then
            error "Decryption failed — wrong password?"
            _SECRET_PASS=""
            return 1
        fi
        success "Decrypted $(basename "$src")"
    fi

    link_file "$src" "$target"
}

# ── Subcommands ───────────────────────────────────────────────

secret_add() {
    local file="${1:?Usage: ./install.sh secret add <file>}"
    file="${file#"$REPO_DIR/"}"
    local abs="$REPO_DIR/$file"

    if [ ! -f "$abs" ]; then
        error "File not found: $file"
        return 1
    fi
    if _is_secret "$file"; then
        warn "$file is already a secret"
        return 0
    fi

    local pass
    pass="$(_get_password encrypt)"

    _encrypt_file "$abs" "${abs}.enc" "$pass"
    success "Encrypted → ${file}.enc"

    echo "$file" >> "$SECRETFILES"
    success "Tracked in .secretfiles"

    if ! grep -qxF "$file" "$REPO_DIR/.gitignore" 2>/dev/null; then
        echo "$file" >> "$REPO_DIR/.gitignore"
        success "Plaintext added to .gitignore"
    fi

    if git -C "$REPO_DIR" ls-files --error-unmatch "$file" &>/dev/null 2>&1; then
        git -C "$REPO_DIR" rm --cached --quiet "$file"
        success "Removed plaintext from git tracking"
    fi

    echo ""
    info "Next: commit the .enc, .secretfiles, and .gitignore changes"
}

secret_encrypt() {
    local secrets
    secrets="$(_list_secrets)"
    if [ -z "$secrets" ]; then
        warn "No secrets configured. Use: ./install.sh secret add <file>"
        return
    fi

    local pass
    pass="$(_get_password encrypt)"

    echo ""
    while IFS= read -r file; do
        local abs="$REPO_DIR/$file"
        if [ ! -f "$abs" ]; then
            warn "Skip $file (plaintext not found)"
            continue
        fi
        _encrypt_file "$abs" "${abs}.enc" "$pass"
        success "Encrypted $file"
    done <<< "$secrets"
}

secret_decrypt() {
    local secrets
    secrets="$(_list_secrets)"
    if [ -z "$secrets" ]; then
        warn "No secrets configured"
        return
    fi

    local pass
    pass="$(_get_password decrypt)"

    echo ""
    while IFS= read -r file; do
        local abs="$REPO_DIR/$file"
        if [ -f "$abs" ]; then
            success "${_DIM}$file${_NC} (already decrypted)"
            continue
        fi
        if [ ! -f "${abs}.enc" ]; then
            warn "Skip $file (no .enc file)"
            continue
        fi
        if ! _decrypt_file "${abs}.enc" "$abs" "$pass"; then
            error "Failed to decrypt $file — wrong password?"
            _SECRET_PASS=""
            return 1
        fi
        success "Decrypted $file"
    done <<< "$secrets"
}

secret_hint() {
    local hint="$*"
    if [ -z "$hint" ]; then
        if [ -f "$SECRET_HINT_FILE" ]; then
            echo -e "  Current hint: ${_BOLD}$(cat "$SECRET_HINT_FILE")${_NC}"
        else
            warn "No hint set. Usage: ./install.sh secret hint \"your hint text\""
        fi
        return
    fi
    printf '%s' "$hint" > "$SECRET_HINT_FILE"
    success "Hint saved"
}

secret_status() {
    local secrets
    secrets="$(_list_secrets)"
    if [ -z "$secrets" ]; then
        warn "No secrets configured"
        return
    fi

    echo ""
    echo -e "  ${_BOLD}Secret files:${_NC}"
    echo ""

    while IFS= read -r file; do
        local abs="$REPO_DIR/$file"
        local st
        if [ -f "$abs" ] && [ -f "${abs}.enc" ]; then
            st="${_GREEN}✓ decrypted${_NC}"
        elif [ -f "${abs}.enc" ]; then
            st="${_YELLOW}● encrypted only${_NC}"
        elif [ -f "$abs" ]; then
            st="${_RED}✗ plaintext not encrypted${_NC}"
        else
            st="${_RED}✗ missing${_NC}"
        fi
        printf "    %-30s %b\n" "$file" "$st"
    done <<< "$secrets"

    echo ""
    if [ -f "$SECRET_HINT_FILE" ]; then
        echo -e "  Hint: ${_DIM}$(cat "$SECRET_HINT_FILE")${_NC}"
        echo ""
    fi

    echo -e "  Cipher: ${_DIM}${_CIPHER_ARGS[*]}${_NC}"
    echo ""
}

secret_usage() {
    cat <<EOF

  ${_BOLD}Usage:${_NC}  ./install.sh secret <command> [args]

  ${_BOLD}Commands:${_NC}
    add <file>       Mark a file as secret and encrypt it
    encrypt          Re-encrypt all secret files
    decrypt          Decrypt all secret files
    hint [text]      Get or set the password hint
    status           Show status of all secret files

  ${_BOLD}Workflow:${_NC}
    1.  ./install.sh secret hint "my cat's name"
    2.  ./install.sh secret add ssh/config
    3.  git add -A && git commit
    4.  (on new machine) ./install.sh secret decrypt

  In setup.sh, use ${_BOLD}link_secret${_NC} instead of link_file:
    link_secret "\$MODULE_DIR/.my_secret" "\$HOME/.my_secret"

EOF
}

cmd_secret() {
    local subcmd="${1:-help}"; shift 2>/dev/null || true
    case "$subcmd" in
        add)      secret_add "$@" ;;
        encrypt)  secret_encrypt ;;
        decrypt)  secret_decrypt ;;
        hint)     secret_hint "$@" ;;
        status)   secret_status ;;
        help|*)   secret_usage ;;
    esac
}
