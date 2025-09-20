#!/bin/bash

# Check for battery (common path)
if [ -d "/sys/class/power_supply/BAT0" ]; then
  HAS_BATTERY="true"
else
  HAS_BATTERY="false"
fi

# Check for a real screen backlight, ignoring keyboard backlights etc.
if command -v brightnessctl &> /dev/null && [ -n "$(brightnessctl -l -c backlight)" ]; then
  HAS_BRIGHTNESS="true"
else
  HAS_BRIGHTNESS="false"
fi

# Output a JSON object for eww
echo "{\"battery\": $HAS_BATTERY, \"brightness\": $HAS_BRIGHTNESS}"
