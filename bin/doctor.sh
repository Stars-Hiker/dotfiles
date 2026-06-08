#!/usr/bin/env bash
# ==============================================================================
# doctor.sh — quick, SUDO-FREE health check that this machine matches the
# dotfiles. Automates the manual RECOVERY-TEST.md checklist. Exits non-zero if
# any check fails (usable from `make doctor`, scripts, or CI).
#
# Deliberately NOT `set -e`: every check must run and report, not abort on the
# first failure. Checks that would need root (ufw status, snapper list) are
# listed as manual rather than run — see nimrod's "sudo needs a real terminal".
# ==============================================================================
set -uo pipefail

DOTFILES_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

GREEN=$'\e[1;32m'; RED=$'\e[1;31m'; YELLOW=$'\e[1;33m'; RESET=$'\e[0m'
fails=0

ok()   { printf '  %s✓%s %s\n' "$GREEN"  "$RESET" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$RED"    "$RESET" "$1"; fails=$((fails + 1)); }
note() { printf '  %s•%s %s\n' "$YELLOW" "$RESET" "$1"; }
hdr()  { printf '\n%s== %s ==%s\n' "$YELLOW" "$1" "$RESET"; }

# check_link <path> <label> — true if <path> resolves into the dotfiles repo.
check_link() {
    local path="$1" label="$2" real
    if [[ -e "$path" ]] && real="$(realpath -e "$path" 2>/dev/null)" \
       && [[ "$real" == "$DOTFILES_DIR"/* ]]; then
        ok "$label  (${real#"$HOME"/})"
    else
        bad "$label not linked into the repo: $path"
    fi
}

# svc_enabled <unit> <label> — system unit enabled? (query only, no sudo)
svc_enabled() {
    if systemctl is-enabled --quiet "$1" 2>/dev/null; then
        ok "$2 enabled"
    else
        bad "$2 not enabled  (systemctl is-enabled $1)"
    fi
}

hdr "Config symlinks resolve into ${DOTFILES_DIR/#$HOME/~}"
check_link "$HOME/.config/hypr/hyprland.conf" "hypr"
check_link "$HOME/.config/waybar"             "waybar"
check_link "$HOME/.config/kitty/kitty.conf"   "kitty"
check_link "$HOME/.config/nvim"               "nvim"
check_link "$HOME/.config/rofi"               "rofi"
check_link "$HOME/.config/btop/btop.conf"     "btop"
check_link "$HOME/.config/paru/paru.conf"     "paru"
check_link "$HOME/.gitconfig"                 "git"
check_link "$HOME/.zshrc"                      "zsh"

hdr "Shell"
case "${SHELL:-}" in
    */zsh) ok "default shell is zsh" ;;
    *)     bad "default shell is '${SHELL:-unset}', not zsh" ;;
esac
if [[ -d "$HOME/AUR/fzf-tab" ]]; then
    ok "fzf-tab plugin present"
else
    bad "fzf-tab missing (~/AUR/fzf-tab) — tab completion menu won't work"
fi

hdr "Services (query-only, no sudo)"
svc_enabled ufw.service  "ufw"
svc_enabled sddm.service "sddm"
if systemctl is-enabled --quiet tlp.service 2>/dev/null; then
    ok "tlp enabled (laptop)"
else
    note "tlp not enabled (expected on a desktop)"
fi
if systemctl --user is-active --quiet pipewire.service 2>/dev/null; then
    ok "pipewire (user) active"
else
    note "pipewire user service not active (needs a graphical login)"
fi

hdr "Secrets"
if [[ -f "$HOME/.config/age/keys.txt" ]]; then
    ok "age identity present (~/.config/age/keys.txt)"
else
    bad "age identity missing — unseal won't work (~/.config/age/keys.txt)"
fi
if [[ -d "$HOME/.ssh" ]]; then
    perm="$(stat -c '%a' "$HOME/.ssh" 2>/dev/null || echo '?')"
    if [[ "$perm" == "700" ]]; then
        ok "SSH dir present, perms 700 (~/.ssh)"
    else
        note "SSH dir perms are $perm, expected 700 (~/.ssh)"
    fi
else
    bad "SSH dir missing (~/.ssh) — secrets not restored?"
fi

hdr "Package-list drift (no sudo)"
if command -v pacman >/dev/null 2>&1; then
    native="$DOTFILES_DIR/pkglists/pkgs-native.txt"
    if [[ -f "$native" ]]; then
        n="$(comm -23 <(sort "$native") <(pacman -Qqen 2>/dev/null | sort) | wc -l)"
        if [[ "$n" -eq 0 ]]; then
            ok "all native pkglist packages are installed"
        else
            note "$n package(s) in pkgs-native.txt are not installed (re-run recovery or paru -S them)"
        fi
    else
        note "no native pkglist at $native"
    fi
else
    note "pacman not found — skipping package drift"
fi

hdr "Needs root — check by hand"
note "sudo ufw status verbose       # firewall rules active"
note "sudo snapper -c root list     # Btrfs snapshots (if root is Btrfs)"

echo
if [[ "$fails" -eq 0 ]]; then
    printf '%sAll automated checks passed.%s\n' "$GREEN" "$RESET"
    exit 0
else
    printf '%s%d check(s) failed — see ✗ above.%s\n' "$RED" "$fails" "$RESET"
    exit 1
fi
