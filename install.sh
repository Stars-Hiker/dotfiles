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

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
backed_up=0

# already_deployed <relpath> — true if the target is a symlink, or resolves
# (through an already-symlinked parent) into the dotfiles repo. Such a path is
# NOT a conflict and must never be backed up — doing so would `mv` our own repo
# files out through the symlink. This makes re-runs safe/idempotent.
already_deployed() {
    local target="$HOME/$1" real
    [[ -L "$target" ]] && return 0
    real="$(realpath -m "$target" 2>/dev/null)" || return 1
    [[ "$real" == "$DOTFILES_DIR"/* ]]
}

backup_target() {                       # $1 = path relative to $HOME
    local rel="$1" target="$HOME/$1"
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$target" "$BACKUP_DIR/$rel"
    echo "  backed up: $target"
    backed_up=1
}

# ── Pass 1: move aside pre-existing REAL directories that collide with a stow
#    "link root" ───────────────────────────────────────────────────────────────
# Distros pre-seed config dirs (e.g. CachyOS ships ~/.config/hypr). If such a
# directory already exists, stow *folds* into it and silently deploys only part
# of the package — leaving sourced subdirs (like hypr/conf/) missing. To force a
# clean single symlink, we move the whole colliding directory aside first.
#
# Which dirs are "link roots"? Count how many packages contain each directory:
#   - shared across packages (e.g. .config, count >= 2)  → stow descends, keep it
#   - unique to one package whose PARENT is shared/$HOME  → stow symlinks it;
#     this is the link root (e.g. .config/hypr) — back it up if it's a real dir.
declare -A dircount
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$pkg" ]] || continue
    while IFS= read -r -d '' d; do
        rel="${d#"$pkg"/}"
        dircount["$rel"]=$(( ${dircount["$rel"]:-0} + 1 ))
    done < <(find "$pkg" -mindepth 1 -type d -print0)
done

for pkg in "${PACKAGES[@]}"; do
    [[ -d "$pkg" ]] || continue
    while IFS= read -r -d '' d; do
        rel="${d#"$pkg"/}"
        [[ "${dircount["$rel"]:-0}" -eq 1 ]] || continue   # not unique → shared, keep
        already_deployed "$rel" && continue                # already linked → leave
        parent="$(dirname "$rel")"
        # link root = parent is $HOME ('.') or a dir shared by other packages
        if [[ "$parent" == "." || "${dircount["$parent"]:-0}" -ge 2 ]]; then
            [[ -d "$HOME/$rel" ]] && backup_target "$rel"
        fi
    done < <(find "$pkg" -mindepth 1 -type d -print0)
done

# ── Pass 2: move aside any remaining conflicting REAL files ───────────────────
# /etc/skel copies (~/.bashrc, ~/.zshrc, …) and stray files in shared dirs.
# already_deployed() skips anything that already resolves into the repo, so
# re-running this script never cannibalises our own files.
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$pkg" ]] || { echo "skip: package '$pkg' not found"; continue; }
    while IFS= read -r -d '' f; do
        rel="${f#"$pkg"/}"
        already_deployed "$rel" && continue
        [[ -e "$HOME/$rel" ]] && backup_target "$rel"
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
