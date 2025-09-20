#!/bin/bash
# Arguments: BSSID, SSID, Security
BSSID="$1"
SSID="$2"
SECURITY="$3"

# Close the wifi menu after selection
eww update show_wifi_menu=false

# If the network is secure and not already configured, prompt for a password
if [[ "$SECURITY" != "--" ]] && ! nmcli c | grep -q "^$SSID "; then
    # Use wofi for a password prompt instead of rofi
    PASSWORD=$(echo "" | wofi --dmenu --password --prompt "Password for $SSID" --hide-scroll --allow-markup --insensitive)

    # If a password was entered, try to connect
    if [[ -n "$PASSWORD" ]]; then
        nmcli device wifi connect "$BSSID" password "$PASSWORD"
        # Send notification about connection attempt
        notify-send "WiFi" "Attempting to connect to $SSID..."
    fi
else
    # Connect to an open or known network
    nmcli device wifi connect "$BSSID"
    notify-send "WiFi" "Connecting to $SSID..."
fi
