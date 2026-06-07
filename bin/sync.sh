#!/usr/bin/env bash
# ==============================================================================
# sync.sh — snapshot the current machine state and push it to GitHub.
#   1. regenerate package lists   2. commit any changes   3. push
# Run via the `dotsync` alias whenever you've tweaked your setup.
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
cd "$DOTFILES_DIR"

# 1. Refresh package lists (redundant if the pacman hook is installed, but makes
#    `dotsync` self-contained and correct even on a machine without the hook).
bash bin/pkg-snapshot.sh

# 2. Commit if anything changed.
git add -A
if git diff --cached --quiet; then
    echo "Nothing to sync — already up to date with GitHub."
else
    git status -sb
    git commit -m "sync $(date '+%Y-%m-%d %H:%M')"
fi

# 3. Push.
git push
echo "Dotfiles synced -> $(git remote get-url origin)"
