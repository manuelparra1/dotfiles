#!/bin/bash

# Toggle MPD playback
mpc toggle > /dev/null

# Check the current status and show appropriate notification
if mpc status | grep -q "\[playing\]"; then
    notify-send "Music (Resumed)" "$(mpc current)"
elif mpc status | grep -q "\[paused\]"; then
    notify-send "Music (Paused)" "$(mpc current)"
else
    notify-send "Music" "Stopped"
fi
