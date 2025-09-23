#!/usr/bin/env bash

# Get the active SSID
SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

# Print the SSID
echo "$SSID"
