#!/bin/env bash

# Get current state
CURRENT_STATE=$(eww get show_calendar)

# Toggle the calendar and close wifi menu
if [ "$CURRENT_STATE" = "true" ]; then
    eww update show_calendar=false
else
    eww update show_calendar=true
    eww update show_wifi_menu=false
fi
