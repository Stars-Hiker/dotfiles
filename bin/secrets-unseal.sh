#!/usr/bin/env bash
# ==============================================================================
# secrets-unseal.sh — decrypt secrets/secrets.tar.age back into $HOME
#
# Requires your private age identity. Default location ~/.config/age/keys.txt;
# override with AGE_IDENTITY=/path/to/keys.txt. Restore that key from Bitwarden
# or your USB BEFORE running this. Existing files are overwritten (restore).
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
ENC="$DOTFILES_DIR/secrets/secrets.tar.age"
IDENTITY="${AGE_IDENTITY:-$HOME/.config/age/keys.txt}"

command -v age >/dev/null 2>&1 || { echo "ERROR: 'age' not installed (sudo pacman -S age)" >&2; exit 1; }
[[ -f "$ENC" ]]      || { echo "ERROR: no encrypted blob at $ENC" >&2; exit 1; }
[[ -f "$IDENTITY" ]] || {
    echo "ERROR: no age identity at $IDENTITY" >&2
    echo "  Restore it from Bitwarden/USB, or set AGE_IDENTITY=/path/to/keys.txt" >&2
    exit 1
}

age -d -i "$IDENTITY" "$ENC" | tar -C "$HOME" -xzf -

# Lock down SSH material (ssh refuses keys that are group/world readable).
if [[ -d "$HOME/.ssh" ]]; then
    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f -exec chmod 600 {} +
fi

echo "Unsealed secrets into $HOME"
