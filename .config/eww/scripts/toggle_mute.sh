#!/bin/bash

# Check if audio is currently muted
if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
    # Unmute
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    notify-send "Audio" "Unmuted" -t 1000
else
    # Mute
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
    notify-send "Audio" "Muted" -t 1000
fi
