#!/bin/bash

# Get volume string from wpctl (e.g., "Volume: 0.40 [MUTED]")
WP_OUTPUT=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

# Safety Check: If wpctl fails or output is empty, exit cleanly
if [ -z "$WP_OUTPUT" ]; then
    echo "..."
    exit 0
fi

# 1. Parse Volume (Convert 0.40 to 40)
# We use awk to grab the second column. 
VOLUME_PERCENT=$(echo "$WP_OUTPUT" | awk '{print int($2 * 100)}')

# 2. Check for Mute
# If the string contains [MUTED], set flag
if [[ "$WP_OUTPUT" == *"[MUTED]"* ]]; then
    IS_MUTED="yes"
else
    IS_MUTED=""
fi

# 3. Determine Icon & Text
if [ -n "$IS_MUTED" ]; then
    ICON="󰝟"
    FULL_TEXT="$ICON Muted"
elif [ "$VOLUME_PERCENT" -eq 0 ]; then
    ICON=""
    FULL_TEXT="$ICON ${VOLUME_PERCENT}%"
elif [ "$VOLUME_PERCENT" -lt 50 ]; then
    ICON=""
    FULL_TEXT="$ICON ${VOLUME_PERCENT}%"
else
    ICON=""
    FULL_TEXT="$ICON ${VOLUME_PERCENT}%"
fi

echo "$FULL_TEXT"

# Handle click event (Left Click toggles mute)
case "$BLOCK_BUTTON" in
    1) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -RTMIN+10 i3blocks ;;
esac
