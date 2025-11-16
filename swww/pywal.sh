#!/bin/bash

if ! pgrep -x swww-daemon > /dev/null; then
    swww-daemon &
    sleep 2
fi

WALLPAPER_DIR="$HOME/Downloads/wallpapers"
INTERVAL=1800

TRANSITIONS=("fade" "grow" "outer" "wave")

while true; do
    wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
    
    transition=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}
    
    if [ -f "$wallpaper" ]; then
        # Generate colors
        wal -i "$wallpaper" -n -q
        
        # Set wallpaper
        swww img "$wallpaper" \
            --transition-type "$transition" \
            --transition-duration 3 \
            --transition-fps 60 \
            --transition-angle $((RANDOM % 360))
        
        # Reload Waybar and Kitty
        sleep 0.5
        pkill -SIGUSR2 waybar
# 	kitty @ --to unix:/tmp/kitty set-colors -a ~/.cache/wal/colors-kitty.conf 2>/dev/null       
        echo "$(date): Set wallpaper to $(basename "$wallpaper") with $transition transition"
    fi
    
    sleep $INTERVAL
done
