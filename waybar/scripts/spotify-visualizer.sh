#!/bin/bash

# Check if Spotify is running
if ! pgrep -x spotify > /dev/null; then
    echo "🎵"
    exit 0
fi

# Get current track info
title=$(playerctl -p spotify metadata title 2>/dev/null)
artist=$(playerctl -p spotify metadata artist 2>/dev/null)

# Debug log
echo "$(date): title='$title' artist='$artist'" >> /tmp/spotify-viz.log

if [ -z "$title" ]; then
    echo "🎵"
    exit 0
fi

# Combine title and artist
if [ -n "$artist" ]; then
    full_title="$title - $artist"
else
    full_title="$title"
fi

# Truncate if too long
if [ ${#full_title} -gt 25 ]; then
    display_title="${full_title:0:22}..."
else
    display_title="$full_title"
fi

echo "$display_title"