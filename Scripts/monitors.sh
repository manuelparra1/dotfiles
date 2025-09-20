#!/bin/bash

# Check if HDMI-1 is connected
if xrandr | grep -q "HDMI-1 connected"; then
    echo "HDMI-1 detected. Extending desktop..."
    # Extend desktop: set HDMI-1 to 1920x1080 and position it to the right of LVDS-1
    xrandr --output HDMI-1 --mode 1920x1080 --right-of LVDS-1
else
    echo "HDMI-1 not detected. No changes made."
fi
