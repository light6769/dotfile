#!/bin/bash

# Start swww daemon
swww-daemon --format xrgb &

# Start hypridle for auto-lock
hypridle &

# Wait for daemon
sleep 1

# Set random wallpaper
wallpaper=$(find ~/Downloads/wallpapers -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
wal -i "$wallpaper" -n -q

# Update Hyprland borders
. ~/.cache/wal/colors.sh
hyprctl keyword general:col.active_border "0xff${color1:1} 0xff${color2:1} 45deg"
hyprctl keyword general:col.inactive_border "0xff${color0:1}"

swww img "$wallpaper" --transition-type fade --transition-duration 2

# Reload swaync
swaync-client --reload-config

# Reload swaync
swaync-client --reload-config

# Start wallpaper rotation
sleep 2
~/.config/swww/anime-rotate.sh &
