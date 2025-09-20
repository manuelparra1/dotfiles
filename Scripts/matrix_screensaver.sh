#!/bin/bash

# # Kill any existing cmatrix processes
# pkill -f cmatrix
#
# # Launch cmatrix instances
# kitty --class="cmatrix_left" -e cmatrix &
#
# hyprctl dispatch togglespecialworkspace matrix_l
hyprctl movetoworkspace matrix_l

# kitty --class="cmatrix_right" -e cmatrix &
#
# hyprctl dispatch togglespecialworkspace matrix_r
# hyperctl movetoworkspace matrix_r
# # Wait for windows to initialize
# sleep 1
#
# # Show special workspace on both monitors
# # hyprctl dispatch workspaceopt allfloating
#
# # Give cmatrix time to render properly
# sleep 2
#
# # Start hyprlock
# hyprlock
#
# # Clean up
# pkill -f cmatrix
# hyprctl dispatch togglespecialworkspace matrix
