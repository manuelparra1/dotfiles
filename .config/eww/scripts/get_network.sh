#!/usr/bin/env bash

# Default icon
ICON="󰤯" # Ethernet icon

# Check if Wi-Fi is the primary connection
if [[ $(nmcli -t -f DEVICE,TYPE,STATE d | grep "wifi" | grep "connected") ]]; then
    ICON="󰤨" # Wi-Fi icon
fi

# Check for no connection
if ! nmcli d | grep -q " connected"; then
    ICON="󰤮" # Disconnected icon
fi

echo "$ICON"
