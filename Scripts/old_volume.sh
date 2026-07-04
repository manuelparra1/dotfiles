#!/bin/bash

# Get volume and mute status using pactl
SINK_INFO=$(pactl get-sink-volume @DEFAULT_SINK@)
VOLUME_PERCENT=$(echo "$SINK_INFO" | grep -o '[0-9]\+%' | head -n 1)
IS_MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ | grep 'yes')

# Determine icon and tooltip
if [ -n "$IS_MUTED" ]; then
    ICON="󰝟"
    # # FULL_TEXT="$ICON muted"
    # FULL_TEXT="muted $ICON"
    FULL_TEXT="$ICON"
elif [ "$VOLUME_PERCENT" == "0%" ]; then
    ICON=""
    # FULL_TEXT="$ICON 0%"
    # FULL_TEXT="0% $ICON"
    FULL_TEXT="$ICON"
# Remove the '%' for numerical comparison
elif (( ${VOLUME_PERCENT%%%} < 50 )); then
    ICON=""
    # FULL_TEXT="$ICON $VOLUME_PERCENT"
    # FULL_TEXT="$VOLUME_PERCENT $ICON"
    FULL_TEXT="$ICON"
else
    ICON=""
    # FULL_TEXT="$ICON $VOLUME_PERCENT"
    # FULL_TEXT="$VOLUME_PERCENT $ICON"
    FULL_TEXT="$ICON"
fi

# Print the result
echo "$FULL_TEXT"

# Handle click event
case "$BLOCK_BUTTON" in
    1) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
esac
