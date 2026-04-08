#!/bin/bash

# Options
lock="󰌾  Lock"
logout="󰍃  Logout"
suspend="󰤄  Suspend"
reboot="󰜉  Reboot"
shutdown="󰐥  Shutdown"

# Rofi command — pointe vers ton thème existant
rofi_cmd() {
    rofi -dmenu \
        -p "⏻" \
        -theme ~/.config/rofi/powermenu.rasi
}

chosen=$(printf "%s\n%s\n%s\n%s\n%s" "$lock" "$logout" "$suspend" "$reboot" "$shutdown" | rofi_cmd)

case "$chosen" in
    "$lock")     hyprlock ;;
    "$logout")   hyprctl dispatch exit ;;
    "$suspend")  systemctl suspend && hyprlock ;;
    "$reboot")   systemctl reboot ;;
    "$shutdown") systemctl poweroff ;;
esac
