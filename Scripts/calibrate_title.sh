#!/bin/bash

# --- CONFIGURATION ---
CONFIG_FILE="$HOME/.config/i3blocks_center_config"
REQUIRED_DEPS=("slop" "xdpyinfo")

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- DEPENDENCY CHECK ---
for dep in "${REQUIRED_DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        echo -e "${RED}[X] Missing: $dep${NC}"
        echo "Please run: sudo xbps-install -S slop xdpyinfo"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}--- i3blocks Centering Setup ---${NC}"
echo "We will measure 3 things: Right Icons, Empty Spaces, and Text Characters."

# --- STEP 1: RIGHT SIDE MODULES ---
while true; do
    echo ""
    echo -e "${YELLOW}STEP 1: Measure Right-Side Modules.${NC}"
    echo "   Draw a box covering ALL icons on the right (Wifi, Clock, Battery)."
    echo "   (Press Enter to start)"
    read -r

    if OUTPUT=$(slop -f "%w" 2>/dev/null); then
        RIGHT_PX=$OUTPUT
        if [[ "$RIGHT_PX" =~ ^[0-9]+$ ]] && [ "$RIGHT_PX" -gt 0 ]; then
            echo -e "${GREEN}-> Right block width: ${RIGHT_PX}px${NC}"
            break
        else
            echo -e "${RED}-> Invalid selection. Try again.${NC}"
        fi
    else
        echo -e "${YELLOW}-> Cancelled. Retrying...${NC}"
    fi
done

# --- STEP 2: SPACE WIDTH (PADDING) ---
while true; do
    echo ""
    echo -e "${YELLOW}STEP 2: Measure Space Width (Skinny).${NC}"
    echo "   Draw a box strictly inside the brackets covering the 10 spaces."
    echo ""
    echo "   [          ]"
    echo ""
    echo "   (Press Enter to start)"
    read -r

    if OUTPUT=$(slop -f "%w" 2>/dev/null); then
        BLOCK=$OUTPUT
        if [[ "$BLOCK" =~ ^[0-9]+$ ]]; then
            SPACE_PX=$(( BLOCK / 10 ))
            if [ "$SPACE_PX" -lt 1 ]; then SPACE_PX=3; fi # Minimum safety
            echo -e "${GREEN}-> 10 spaces = ${BLOCK}px${NC}"
            echo -e "${GREEN}-> Padding Unit: ${SPACE_PX}px${NC}"
            break
        fi
    fi
done

# --- STEP 3: CHARACTER WIDTH (TEXT) ---
while true; do
    echo ""
    echo -e "${YELLOW}STEP 3: Measure Text Width (Fat).${NC}"
    echo "   Draw a box strictly inside the brackets covering the 10 letters."
    echo "   This ensures long titles don't drift."
    echo ""
    echo "   [xxxxxxxxxx]"
    echo ""
    echo "   (Press Enter to start)"
    read -r

    if OUTPUT=$(slop -f "%w" 2>/dev/null); then
        BLOCK=$OUTPUT
        if [[ "$BLOCK" =~ ^[0-9]+$ ]]; then
            CHAR_PX=$(( BLOCK / 10 ))
            if [ "$CHAR_PX" -lt 1 ]; then CHAR_PX=8; fi # Minimum safety
            echo -e "${GREEN}-> 10 chars = ${BLOCK}px${NC}"
            echo -e "${GREEN}-> Text Unit: ${CHAR_PX}px${NC}"
            break
        fi
    fi
done

# --- SAVE CONFIG ---
# We default EXTRA_SPACES to 45 (your tuned value) but let you edit it manually later
mkdir -p "$(dirname "$CONFIG_FILE")"

cat > "$CONFIG_FILE" <<EOF
RIGHT_PX=$RIGHT_PX
SPACE_PX=$SPACE_PX
CHAR_PX=$CHAR_PX
EXTRA_SPACES=45
EOF

echo ""
echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
echo "Restart i3 (Mod+Shift+R) to apply."
