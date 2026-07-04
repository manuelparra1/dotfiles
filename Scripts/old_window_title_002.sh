#!/bin/bash

# Load calibration data
CONFIG_FILE="$HOME/.config/i3blocks_center_config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Fallback defaults if you haven't run the setup script yet
    RIGHT_PX=200
    SPACE_PX=10
fi

MAX_TITLE_LEN=60

# --- GET SCREEN RESOLUTION (UPDATED) ---
# Try to get the width of the connected monitor using xrandr
# This grabs the first number (width) from the first connected screen found.
if command -v xrandr &> /dev/null; then
    # Returns something like "2560" from "2560x1440+0+0"
    SCREEN_WIDTH=$(xrandr | grep -w "connected" | awk -F'[ x+]' '{print $3}' | head -n1)
fi

# Fallback/Safety Check
if ! [[ "$SCREEN_WIDTH" =~ ^[0-9]+$ ]]; then
    # If detection failed, Force it to your actual resolution
    # CHANGE THIS 1920 TO YOUR ACTUAL WIDTH (e.g., 2560 or 3440)
    SCREEN_WIDTH=1920
fi


# Calculate the exact center pixel of the screen
HALF_SCREEN=$((SCREEN_WIDTH / 2))



xtitle -s | while read -r raw_title; do

    # 1. Truncate Title
    if [[ ${#raw_title} -gt $MAX_TITLE_LEN ]]; then
        title="${raw_title:0:$((MAX_TITLE_LEN-3))}..."
    else
        title="$raw_title"
    fi
    
    # 2. Calculate Title Width in Pixels (Approximate)
    # We assume standard characters are roughly same width as spaces 
    # (True for Monospace fonts, which i3bar usually is)
    title_width_px=$(( ${#title} * SPACE_PX ))
    half_title_px=$(( title_width_px / 2 ))

    # 3. THE LOGIC
    # We need the text to be centered at HALF_SCREEN.
    # But i3blocks fills from the right.
    # The empty space we need to "push" the title left is:
    # Space = (Distance from Right Edge to Center) - (Half Title Width) - (Right Icons Width)
    
    # Distance from Right Edge to Center is HALF_SCREEN.
    pad_pixels=$(( HALF_SCREEN - half_title_px - RIGHT_PX ))

    # Convert pixels to spaces
    pad_spaces=$(( pad_pixels / SPACE_PX ))

    # Safety check
    if [[ $pad_spaces -lt 0 ]]; then pad_spaces=0; fi

    # 4. Output
    # We only really care about Right Padding to force the center position.
    # Left padding is just aesthetic to fill the gap.
    printf "%s%*s\n" "$title" $pad_spaces ""

done
