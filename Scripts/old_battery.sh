#!/usr/bin/env bash
# i3blocks battery block with icons by charge level

# Try sysfs first
BAT_PATH="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)"
if [ -n "$BAT_PATH" ]; then
  PCT=$(cat "$BAT_PATH/capacity" 2>/dev/null)
  STATE=$(cat "$BAT_PATH/status" 2>/dev/null)
else
  # Fallback to acpi if available
  if command -v acpi >/dev/null 2>&1; then
    # Example: Battery 0: Discharging, 73%, 02:15:00 remaining
    LINE="$(acpi -b | head -n1)"
    PCT="$(printf '%s\n' "$LINE" | grep -o '[0-9]\+%' | tr -d '%')"
    STATE="$(printf '%s\n' "$LINE" | awk -F'[:, ]+' '{print $3}')"
  else
    echo " --"
    exit 0
  fi
fi

# Normalize state
# Possible values commonly: Charging, Discharging, Full, Unknown, Not charging
STATE="${STATE:-Unknown}"

# this ensures the `STATE` variable has a value: if `STATE` is already set (and not empty), it keeps that value; otherwise it assigns `"Unknown"` as the default. This normalizes the state to one of the expected strings.


# Choose icon set (Font Awesome Nerd Font example); adjust to preference
# Charging icons (bolt overlay) and discharging icons:
icon_empty=""
icon_low=""
icon_mid=""
icon_high=""
icon_full=""
icon_charging=""  # shown alongside level when charging

# Thresholds (customize)
t_low=15
t_mid=35
t_high=65
t_full=90

# Determine base icon by percentage
if [ -z "$PCT" ]; then
  ICON="$icon_empty"
elif [ "$PCT" -le "$t_low" ]; then
  ICON="$icon_empty"
elif [ "$PCT" -le "$t_mid" ]; then
  ICON="$icon_low"
elif [ "$PCT" -le "$t_high" ]; then
  ICON="$icon_mid"
elif [ "$PCT" -le "$t_full" ]; then
  ICON="$icon_high"
else
  ICON="$icon_full"
fi

# Color suggestions via i3blocks (optional)
# Output format: full_text [\nshort_text] [\ncolor] [\nbackground]...
COLOR=""
if [ -n "$PCT" ] && [ "$PCT" -le "$t_low" ] && [ "$STATE" = "Discharging" ]; then
  COLOR="#ff5555"
elif [ "$STATE" = "Charging" ]; then
  COLOR="#8ec07c"
fi

# Compose text; include bolt when charging
if [ "$STATE" = "Charging" ]; then
  TEXT="$icon_charging $ICON ${PCT:---}%"
else
  # TEXT="$ICON ${PCT:---}%"
  TEXT="${PCT:---}% $ICON"
fi

# Print for i3blocks
echo "$TEXT"
echo "$TEXT"
[ -n "$COLOR" ] && echo "$COLOR"
