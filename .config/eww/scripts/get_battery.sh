#!/bin/bash

BAT_PATH="/sys/class/power_supply/BAT0"

# If on a desktop without a battery, return default values
if [ ! -d "$BAT_PATH" ]; then
  if [ "$1" = "icon" ]; then
    echo "" # Return a "plug" icon
  else
    echo "100" # Return 100 percent
  fi
  exit
fi

# --- Original script logic for laptops ---
per="$(cat "$BAT_PATH/capacity")"

icon() {
  [ "$(cat "$BAT_PATH/status")" = "Charging" ] && echo "" && exit

  if [ "$per" -gt "90" ]; then
    icon=""
  elif [ "$per" -gt "80" ]; then
    icon=""
  elif [ "$per" -gt "60" ]; then
    icon=""
  elif [ "$per" -gt "40" ]; then
    icon=""
  elif [ "$per" -gt "20" ]; then
    icon=""
  else
    icon=""
  fi
  echo "$icon"
}

percent() {
  echo "$per"
}

case "$1" in
  "icon") icon ;;
  "percent") percent ;;
  *) echo "$per" ;;
esac
