#!/bin/bash

# Configuration
# ------------------------------
ZONE="/sys/class/thermal/thermal_zone1/temp"
CRIT_TEMP=85   # Temp to trigger notification
SAFE_TEMP=80   # Temp to reset the notification lock
LOCK_FILE="/tmp/cpu_crit_lock"

# Read Temperature
# ------------------------------
TEMP_RAW=$(cat "$ZONE")
TEMP_C=$((TEMP_RAW / 1000))
ICON=""

# Notification Logic (Dunst)
# ------------------------------
# 1. If Temp >= Critical AND Lock file doesn't exist -> Notify & Create Lock
if [ "$TEMP_C" -ge "$CRIT_TEMP" ] && [ ! -f "$LOCK_FILE" ]; then
    notify-send -u critical \
                -t 10000 \
                "󰈸 CPU Critical" \
                "Temperature reached ${TEMP_C}°C. Throttling may occur."
    touch "$LOCK_FILE"
fi

# 2. If Temp < Safe AND Lock file exists -> Remove Lock (Rearm)
if [ "$TEMP_C" -lt "$SAFE_TEMP" ] && [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE"
    # Optional: Notify that it has cooled down
    notify-send -u low "CPU Cooled" "Temperature dropped to ${TEMP_C}°C."
fi

# Color Logic for i3blocks
# ------------------------------
COLOR="#494d64" # Catppuccin Macchiato Surface1

if [ "$TEMP_C" -ge 60 ]; then
    COLOR="#f5a97f" # Orange
fi

if [ "$TEMP_C" -ge 80 ]; then
    COLOR="#ed8796" # Red
fi

# Output for i3blocks
# ------------------------------
echo "$ICON ${TEMP_C}°C"
echo "${TEMP_C}°C"
echo "$COLOR"
