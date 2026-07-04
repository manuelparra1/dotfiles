#!/bin/bash

# --- CONFIGURATION ---
CONFIG_FILE="$HOME/.config/i3blocks_center_config"

# Load config
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Defaults if file is missing
    RIGHT_PX=220
    SPACE_PX=3
    CHAR_PX=8       # Default fat width
    EXTRA_SPACES=45 # Default offset
fi

# Safety checks
if [ -z "$SPACE_PX" ]; then SPACE_PX=3; fi
if [ -z "$CHAR_PX" ]; then CHAR_PX=8; fi
if [ -z "$EXTRA_SPACES" ]; then EXTRA_SPACES=45; fi

# --- DETECT SCREEN ---
if command -v xrandr &> /dev/null; then
    SCREEN_WIDTH=$(xrandr | grep -w "connected" | awk -F'[ x+]' '{print $3}' | head -n1)
else
    SCREEN_WIDTH=1920
fi
if ! [[ "$SCREEN_WIDTH" =~ ^[0-9]+$ ]]; then SCREEN_WIDTH=1920; fi
HALF_SCREEN=$((SCREEN_WIDTH / 2))

# --- MAIN LOOP ---
xtitle -s | while read -r raw_title; do

    # 1. Truncate
    title="${raw_title:-}"
    if [[ ${#title} -gt 60 ]]; then title="${title:0:57}..."; fi

    # 2. Calculate TEXT Width (Using the Measured CHAR_PX)
    text_visual_width=$(( ${#title} * CHAR_PX ))
    half_text_width=$(( text_visual_width / 2 ))
    
    # 3. Calculate Padding Needed
    pad_pixels=$(( HALF_SCREEN - half_text_width - RIGHT_PX ))
    if [[ $pad_pixels -lt 0 ]]; then pad_pixels=0; fi

    # 4. Convert Padding to Spaces (Using the Measured SPACE_PX)
    base_spaces=$(( pad_pixels / SPACE_PX ))
    
    # Add manual offset
    total_spaces=$(( base_spaces + EXTRA_SPACES ))

    # 5. Output
    printf "%s%*s\n" "$title" $total_spaces ""

done
