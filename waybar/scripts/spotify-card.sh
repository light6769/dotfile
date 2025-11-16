#!/bin/bash

# Check if Spotify is running
if ! pgrep -x spotify > /dev/null; then
    notify-send "Spotify" "Spotify is not running"
    exit 1
fi

# Get current track info
artist=$(playerctl -p spotify metadata artist 2>/dev/null)
title=$(playerctl -p spotify metadata title 2>/dev/null)
album=$(playerctl -p spotify metadata album 2>/dev/null)
artUrl=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)
status=$(playerctl -p spotify status 2>/dev/null)
position=$(playerctl -p spotify position 2>/dev/null)
length=$(playerctl -p spotify metadata mpris:length 2>/dev/null)

# Calculate progress percentage
if [ -n "$position" ] && [ -n "$length" ]; then
    length_sec=$((length / 1000000))
    progress=$((position * 100 / length_sec))
else
    progress=0
fi

# Create notification with album art
if [ -n "$artUrl" ]; then
    artPath="/tmp/spotify_cover.jpg"
    curl -s "$artUrl" -o "$artPath" 2>/dev/null
    
    notify-send -i "$artPath" -t 5000 "Now Playing" \
        "<b>$title</b>\n$artist\n<i>$album</i>\n\nProgress: $progress%"
else
    notify-send -t 5000 "Now Playing" \
        "<b>$title</b>\n$artist\n<i>$album</i>\n\nProgress: $progress%"
fi

# Alternative: Create a simple rofi menu for controls
echo -e "⏮ Previous\n⏯ Play/Pause\n⏭ Next\n🔀 Shuffle\n🔁 Repeat" | \
rofi -dmenu -p "Spotify Controls" -theme-str 'window {width: 300px;}' | \
while read -r choice; do
    case "$choice" in
        *Previous*) playerctl -p spotify previous ;;
        *Play*) playerctl -p spotify play-pause ;;
        *Next*) playerctl -p spotify next ;;
        *Shuffle*) playerctl -p spotify shuffle toggle ;;
        *Repeat*) playerctl -p spotify loop toggle ;;
    esac
done
