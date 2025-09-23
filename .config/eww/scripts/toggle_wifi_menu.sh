#!/usr/bin/env bash

# Check if the wifi menu window is currently open
if eww active-windows | grep -q "wifi_menu_window"; then
    # Close the wifi menu
    eww close wifi_menu_window
else
    # Open the wifi menu and close calendar if it's open
    eww close the_calendar_window 2>/dev/null || true
    eww open wifi_menu_window
fi
