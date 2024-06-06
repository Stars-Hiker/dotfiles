#!/bin/bash
  
WALLPAPER_DIR="/home/hiker/Wallpapers"

#pgrep -x "swww-daemon" > /dev/null || { swww-daemon & sleep 1; }

change_wallpaper() {
    WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.png" \)))
    [ ${#WALLPAPERS[@]} -eq 0 ] && exit 1
    swww img "${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
}

#trap change_wallpaper SIGUSR1

change_wallpaper

while true; do
    sleep 300
    change_wallpaper
done
