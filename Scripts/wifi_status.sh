#!/bin/bash

# When the block is clicked, use rofi to show available networks.
if [ "$BLOCK_BUTTON" = "1" ]; then
    # List available WiFi networks in terse (colon-separated) format.
    networks=$(nmcli -t -f SSID,SECURITY dev wifi list | sed '/^$/d')
    # Show the list in rofi; the output is the SSID (first field).
    # selected=$(echo "$networks" | rofi -dmenu -i -p "WiFi" | cut -d: -f1)
    selected=$(echo "$networks" | rofi -dmenu -i -p "WiFi:" -width 50% -theme ~/.config/rofi/like_wofi.rasi | cut -d: -f1)
    if [ -n "$selected" ]; then
         # Attempt connection; if a password is needed, nmcli will prompt.
         nmcli dev wifi connect "$selected"
    fi
    exit
fi

# --- Regular status display below ---

# Get info for the currently connected network using terse output.
wifi_info=$(nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list | grep '^*' | head -n1)
signal=$(echo "$wifi_info" | cut -d: -f2)
ssid=$(echo "$wifi_info" | cut -d: -f3-)

# Choose the appropriate icon based on the signal strength.
if [ -z "$signal" ]; then
    icon="󰤮"  # No connection icon
elif [ "$signal" -ge 75 ]; then
    icon="󰤨"  # Excellent signal
elif [ "$signal" -ge 50 ]; then
    icon="󰤥"  # Good signal
elif [ "$signal" -ge 25 ]; then
    icon="󰤢"  # Fair signal
else
    icon="󰤟"  # Weak signal
fi

# echo "$icon $ssid"
echo $icon
