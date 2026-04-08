#!/bin/bash
# wallpaper.sh — awww wallpaper manager
# • Auto-rotates every 30 minutes
# • Call with "next" arg to jump to next wallpaper manually
# Usage:
#   wallpaper.sh          → start daemon + begin auto-rotation
#   wallpaper.sh next     → switch to next wallpaper immediately

WALLPAPER_DIR="$HOME/Wallpapers/wall"
INTERVAL=1800   # seconds (30 minutes)
INDEX_FILE="/tmp/.awww_index"
PID_FILE="/tmp/.awww_rotate.pid"

# ── Transition settings ────────────────────────────────────────────────────────
TRANSITION_TYPE="grow"          # grow | fade | wipe | wave | any | outer | center
TRANSITION_POS="center"
TRANSITION_DURATION="1.5"
TRANSITION_FPS="60"

# ── Helpers ────────────────────────────────────────────────────────────────────

get_wallpapers() {
    shopt -s nullglob globstar nocaseglob
    local -a walls=(
        "$WALLPAPER_DIR"/*.{jpg,jpeg,png,gif,webp}
        "$WALLPAPER_DIR"/**/*.{jpg,jpeg,png,gif,webp}
    )
    shopt -u nullglob globstar nocaseglob

    # Deduplicate and sort
    printf '%s\n' "${walls[@]}" | sort -u
}

ensure_daemon() {
    if ! pgrep -x awww-daemon > /dev/null 2>&1; then
        awww-daemon &
        sleep 1
    fi
}

set_wallpaper() {
    local wall="$1"
    awww img "$wall" \
        --transition-type     "$TRANSITION_TYPE" \
        --transition-pos      "$TRANSITION_POS" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps      "$TRANSITION_FPS"
    notify-send -i "$wall" "Wallpaper" "$(basename "$wall")" 2>/dev/null || true
}

next_wallpaper() {
    mapfile -t walls < <(get_wallpapers)
    local count=${#walls[@]}

    if [ "$count" -eq 0 ]; then
        notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR" 2>/dev/null
        echo "No wallpapers found in $WALLPAPER_DIR" >&2
        exit 1
    fi

    local idx=0
    if [ -f "$INDEX_FILE" ]; then
        idx=$(( $(cat "$INDEX_FILE") + 1 ))
    fi
    idx=$(( idx % count ))
    echo "$idx" > "$INDEX_FILE"

    set_wallpaper "${walls[$idx]}"
}

# ── Auto-rotation loop ─────────────────────────────────────────────────────────

start_rotation() {
    ensure_daemon
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
    fi

    (
        while true; do
            next_wallpaper
            sleep "$INTERVAL"
        done
    ) &
    echo $! > "$PID_FILE"
}

# ── Entry point ────────────────────────────────────────────────────────────────

case "${1:-}" in
    next)
        ensure_daemon
        next_wallpaper
        ;;
    *)
        start_rotation
        ;;
esac
