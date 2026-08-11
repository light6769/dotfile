#!/bin/bash

# Define the Rofi command
ROFI_CMD="rofi -dmenu -i -p 'WiFi Networks' -no-fixed-num-lines -lines 10"

# Get currently connected network
CONNECTED_SSID=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2}')

# Rescan for networks (ensures fresh list)
nmcli device wifi rescan 2>/dev/null

# Function to convert signal strength to icon
get_signal_icon() {
    local signal=$1
    if [ $signal -ge 80 ]; then
        echo "󰤨"  # Excellent
    elif [ $signal -ge 60 ]; then
        echo "󰤥"  # Good
    elif [ $signal -ge 40 ]; then
        echo "󰤢"  # Fair
    elif [ $signal -ge 20 ]; then
        echo "󰤟"  # Weak
    else
        echo "󰤯"  # Very weak
    fi
}

# Get list of available networks
WIFI_LIST=$(nmcli --fields SSID,SIGNAL,SECURITY device wifi list | tail -n +2 | awk -v connected="$CONNECTED_SSID" '
{
    signal = $(NF-1)
    security = $NF
    ssid = ""
    for(i=1; i<NF-1; i++) {
        ssid = ssid (i>1 ? " " : "") $i
    }
    gsub(/^[ \t]+|[ \t]+$/, "", ssid)
    
    if (ssid != "" && ssid != connected) {
        sec_icon = (security == "--" ? "" : "󰌾")
        printf "%s|%s|%s\n", ssid, signal, sec_icon
    }
}')

# Process the list and add signal icons
FORMATTED_LIST=""
while IFS='|' read -r ssid signal sec_icon; do
    signal_icon=$(get_signal_icon "$signal")
    if [ -n "$sec_icon" ]; then
        FORMATTED_LIST+="$signal_icon  $ssid  $sec_icon\n"
    else
        FORMATTED_LIST+="$signal_icon  $ssid\n"
    fi
done <<< "$WIFI_LIST"

# Add connected network at top
if [[ -n "$CONNECTED_SSID" ]]; then
    FORMATTED_LIST="󰤨  $CONNECTED_SSID  󰄬\n$FORMATTED_LIST"
fi

# Show Rofi menu
SELECTION=$(echo -e "$FORMATTED_LIST" | $ROFI_CMD)

# Exit if no selection
[[ -z "$SELECTION" ]] && exit 0

# If already connected network selected, show disconnect option
if [[ "$SELECTION" == *"󰄬"* ]]; then
    CONFIRM=$(echo -e "Disconnect\nCancel" | rofi -dmenu -p "Action")
    if [[ "$CONFIRM" == "Disconnect" ]]; then
        nmcli connection down "$CONNECTED_SSID"
        notify-send "WiFi" "Disconnected from $CONNECTED_SSID"
    fi
    exit 0
fi

# Extract SSID (remove all icons)
SSID_TO_CONNECT=$(echo "$SELECTION" | sed 's/󰤨//g; s/󰤥//g; s/󰤢//g; s/󰤟//g; s/󰤯//g; s/󰌾//g; s/󰄬//g' | xargs)

# Connect to network
if nmcli device wifi connect "$SSID_TO_CONNECT"; then
    notify-send "WiFi" "Successfully connected to $SSID_TO_CONNECT" -i network-wireless
else
    # If connection fails, try with password prompt
    notify-send "WiFi" "Enter password for $SSID_TO_CONNECT" -i network-wireless
    nmcli --ask device wifi connect "$SSID_TO_CONNECT"
fi
