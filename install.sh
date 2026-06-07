#!/usr/bin/env bash
# ==============================================================================
# dotfiles installer — deploys configs into $HOME via GNU Stow.
# Idempotent: safe to re-run (uses --restow). Called by the postInstall script's
# deploy_dotfiles(), or run manually:  cd ~/.dotfiles && ./install.sh
# ==============================================================================
set -euo pipefail

cd "$(dirname "$(realpath "$0")")"
DOTFILES_DIR="$PWD"

# Stow packages (each is a top-level dir mirroring its place under $HOME).
PACKAGES=(bash hypr kitty nvim rofi waybar zsh)

command -v stow >/dev/null 2>&1 || {
    echo "ERROR: 'stow' is not installed. Install it first: sudo pacman -S stow" >&2
    exit 1
}

# ── Back up any REAL (non-symlink) files that would block stow ────────────────
# A fresh Arch install ships /etc/skel copies (~/.bashrc, ~/.bash_profile, ...).
# Stow refuses to overwrite real files, so move conflicting originals aside.
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
backed_up=0

for pkg in "${PACKAGES[@]}"; do
    [[ -d "$pkg" ]] || { echo "skip: package '$pkg' not found"; continue; }
    while IFS= read -r -d '' f; do
        rel="${f#"$pkg"/}"            # path relative to $HOME
        target="$HOME/$rel"
        if [[ -e "$target" && ! -L "$target" ]]; then
            mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
            mv "$target" "$BACKUP_DIR/$rel"
            echo "  backed up real file: $target"
            backed_up=1
        fi
    done < <(find "$pkg" -type f -print0)
done

# ── Deploy ────────────────────────────────────────────────────────────────────
stow --restow --verbose --target="$HOME" "${PACKAGES[@]}"

# Wallpapers is a plain symlink, not a stow package.
if [[ -d "$DOTFILES_DIR/Wallpapers/Wallpapers" ]]; then
    ln -sfn "$DOTFILES_DIR/Wallpapers/Wallpapers" "$HOME/Wallpapers"
fi

[[ $backed_up -eq 1 ]] && echo "Conflicting originals saved in: $BACKUP_DIR"
echo "Dotfiles deployed."
