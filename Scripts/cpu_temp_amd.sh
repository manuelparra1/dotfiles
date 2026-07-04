#!/bin/bash

# Configuration
# ------------------------------
# 1. Try to get temperature from 'sensors' (lm_sensors)
# Looks for 'Tctl' (AMD) or 'Package id 0' (Intel)
TEMP_C=$(sensors | grep -E '(Tctl|Package id 0)' | awk '{print $2}' | tr -d '+°C' | cut -d. -f1 | head -n1)

# 2. Fallback: If sensors didn't return anything, check /sys/class/thermal
if [ -z "$TEMP_C" ]; then
    # Loops through zones to find one labeled 'x86_pkg_temp' or 'acpitz'
    for zone in /sys/class/thermal/thermal_zone*; do
        TYPE=$(cat "$zone/type")
        if [[ "$TYPE" == "x86_pkg_temp" || "$TYPE" == "acpitz" || "$TYPE" == "k10temp" ]]; then
            TEMP_RAW=$(cat "$zone/temp")
            TEMP_C=$((TEMP_RAW / 1000))
            break
        fi
    done
fi

# 3. Final Fallback: Just grab zone0 if all else fails
[ -z "$TEMP_C" ] && TEMP_C=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}')

CRIT_TEMP=85
SAFE_TEMP=80
LOCK_FILE="/tmp/cpu_crit_lock"
ICON=""

# Notification Logic
# ------------------------------
if [ "$TEMP_C" -ge "$CRIT_TEMP" ] && [ ! -f "$LOCK_FILE" ]; then
    notify-send -u critical -t 10000 "󰈸 CPU Critical" "Temperature reached ${TEMP_C}°C."
    touch "$LOCK_FILE"
fi

if [ "$TEMP_C" -lt "$SAFE_TEMP" ] && [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE"
    notify-send -u low "CPU Cooled" "Temperature dropped to ${TEMP_C}°C."
fi

# Color Logic for i3blocks
# ------------------------------
COLOR="#494d64" # Default
[ "$TEMP_C" -ge 60 ] && COLOR="#f5a97f" # Orange
[ "$TEMP_C" -ge 80 ] && COLOR="#ed8796" # Red

# Output for i3blocks
# ------------------------------
echo "$ICON ${TEMP_C}°C"
echo "${TEMP_C}°C"
echo "$COLOR"
