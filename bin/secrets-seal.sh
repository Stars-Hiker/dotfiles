#!/usr/bin/env bash
# ==============================================================================
# secrets-seal.sh — encrypt sensitive files into secrets/secrets.tar.age
#
# Encrypts to the age recipient (public key) in secrets/recipient.txt. The
# resulting .age blob is safe to commit to git, even a public repo. Decrypt with
# secrets-unseal.sh using your private identity (~/.config/age/keys.txt).
#
# Edit the ITEMS list below to control what gets backed up (paths are relative
# to $HOME). Default: SSH keys/config.
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
SECRETS_DIR="$DOTFILES_DIR/secrets"
RECIPIENT_FILE="$SECRETS_DIR/recipient.txt"
OUT="$SECRETS_DIR/secrets.tar.age"

# ── What to seal (relative to $HOME). Add lines to include more secrets. ──────
ITEMS=(
    .ssh
    # .gnupg
    # .config/gh/hosts.yml
)

command -v age >/dev/null 2>&1 || { echo "ERROR: 'age' not installed (sudo pacman -S age)" >&2; exit 1; }
[[ -f "$RECIPIENT_FILE" ]] || {
    echo "ERROR: no recipient at $RECIPIENT_FILE" >&2
    echo "  Generate a key:  age-keygen -o ~/.config/age/keys.txt" >&2
    echo "  Then put its 'Public key:' value in $RECIPIENT_FILE" >&2
    exit 1
}

recipient="$(grep -v '^#' "$RECIPIENT_FILE" | grep -m1 '[^[:space:]]')"
[[ -n "$recipient" ]] || { echo "ERROR: recipient.txt has no key" >&2; exit 1; }

present=()
for i in "${ITEMS[@]}"; do [[ -e "$HOME/$i" ]] && present+=("$i"); done
[[ ${#present[@]} -gt 0 ]] || { echo "ERROR: none of the ITEMS exist under \$HOME" >&2; exit 1; }

mkdir -p "$SECRETS_DIR"
tar -C "$HOME" -czf - "${present[@]}" | age -r "$recipient" -o "$OUT"

echo "Sealed ${#present[@]} item(s) -> $OUT"
printf '  - %s\n' "${present[@]}"
echo "Commit it:  cd '$DOTFILES_DIR' && git add secrets/secrets.tar.age && git commit -m 'update secrets'"
