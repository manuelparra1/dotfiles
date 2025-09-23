#!/usr/bin/env bash

# If brightnessctl doesn't exist or finds no device, output 0.
if ! command -v brightnessctl &> /dev/null || [ -z "$(brightnessctl -l)" ]; then
    echo "0"
    exit
fi

# The device name 'amdgpu_bl0' might not exist.
# A safer way is to just let brightnessctl pick the default.
PERCENTAGE=$(brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}' | tr -d '%')

# Return the value, or 0 if the command failed to produce a value.
echo "${PERCENTAGE:-0}"
