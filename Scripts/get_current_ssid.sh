#!/bin/bash
# Get current connected SSID
current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
echo "${current_ssid:-Not connected}"
