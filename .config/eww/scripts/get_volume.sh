#!/bin/sh
if command -v wpctl &>/dev/null; then
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
        echo 0
    else
        volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
        echo "${volume:-0}"
    fi
else
    echo 0
fi
