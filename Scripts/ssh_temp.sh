#!/bin/bash

# Configuration
ZONE="/sys/class/thermal/thermal_zone1/temp"
INTERVAL=2  # Seconds between updates

# Color Codes (ANSI)
RED='\033[0;31m'
ORANGE='\033[0;33m'
RESET='\033[0m'

echo "Monitoring CPU Temp on $(hostname)... Press [CTRL+C] to stop."
echo "--------------------------------------------------------"

while true; do
    TEMP_RAW=$(cat "$ZONE" 2>/dev/null)
    
    if [ -z "$TEMP_RAW" ]; then
        echo "Error: Could not read thermal zone."
        exit 1
    fi

    TEMP_C=$((TEMP_RAW / 1000))
    TIMESTAMP=$(date +"%H:%M:%S")

    # Determine Color
    COLOR=$RESET
    if [ "$TEMP_C" -ge 80 ]; then
        COLOR=$RED
    elif [ "$TEMP_C" -ge 60 ]; then
        COLOR=$ORANGE
    fi

    # \r returns the cursor to the start of the line so it updates in place
    printf "\r[%s] CPU Temp: %b%d°C%b    " "$TIMESTAMP" "$COLOR" "$TEMP_C" "$RESET"

    sleep "$INTERVAL"
done
