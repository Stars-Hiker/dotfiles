#!/usr/bin/env bash
# ==============================================================================
# pkg-snapshot.sh — write the canonical package lists (single source of truth).
#
#   pkglists/pkgs-native.txt  ← explicitly-installed repo packages  (pacman -Qqen)
#   pkglists/pkgs-aur.txt     ← explicitly-installed foreign/AUR pkgs (pacman -Qqem)
#
# Names only (no versions): version-pinned reinstall is fragile on rolling Arch.
# Run manually, or automatically via the pacman hook installed by postInstall.
# Safe to run as root (the hook does) — output files are chowned back to the
# dotfiles owner.
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
PKGLISTS_DIR="$DOTFILES_DIR/pkglists"
mkdir -p "$PKGLISTS_DIR"

# Exclude packages that can't be reinstalled cleanly on a fresh machine:
#   *-debug              auto-generated debug-symbol packages (e.g. paru-debug)
#   blackarch-mirrorlist needs the BlackArch repo, which a recovery doesn't have
#   netdiscover          on this host it comes from BlackArch; recovery gets it
#                        from the AUR instead (see pkglists/pkgs-aur-extra.txt)
EXCLUDE_RE='(-debug$|^blackarch-mirrorlist$|^netdiscover$)'

LC_ALL=C pacman -Qqen | grep -vE "$EXCLUDE_RE" | sort > "$PKGLISTS_DIR/pkgs-native.txt"
LC_ALL=C pacman -Qqem | grep -vE "$EXCLUDE_RE" | sort > "$PKGLISTS_DIR/pkgs-aur.txt"

# When invoked by the pacman hook we run as root — hand the files back to the
# user who owns the dotfiles tree so `git` and editing keep working.
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    owner="$(stat -c '%U' "$DOTFILES_DIR")"
    chown "$owner":"$(id -gn "$owner")" \
        "$PKGLISTS_DIR/pkgs-native.txt" "$PKGLISTS_DIR/pkgs-aur.txt"
fi

native_n=$(wc -l < "$PKGLISTS_DIR/pkgs-native.txt")
aur_n=$(wc -l < "$PKGLISTS_DIR/pkgs-aur.txt")
echo "pkg-snapshot: ${native_n} native, ${aur_n} AUR -> $PKGLISTS_DIR"
