#!/bin/bash

# --- Highlander Launcher Pattern ---
# Kill any other instances of THIS specific script (listener_volume.sh)
# preventing duplicates when you reload i3
me=$$
pgrep -f "listener_volume.sh" | grep -v "$me" | xargs -r kill

# The Infinite Loop
# If 'pactl subscribe' crashes (server restart), this loop 
# waits 1 second and starts it again.
while true; do
    pactl subscribe | while read -r event; do
        # Filter for 'sink' (output) events
        if echo "$event" | grep -q "sink"; then
            # Send the signal to i3blocks
            pkill -RTMIN+10 i3blocks
        fi
    done
    
    # If we got here, pactl subscribe died. Sleep and retry.
    sleep 1
done
