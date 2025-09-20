#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo '(box :class "workspaces" :orientation "h" :space-evenly true :halign "start" :spacing 3 (eventbox :onhover "eww update ws_hovered_id=1" :onhoverlost "eww update ws_hovered_id=0" (button :class "workspace-btn active" :onclick "hyprctl dispatch workspace 1" "1")))'
    exit
fi

# Get all workspaces and active workspace
workspaces=$(hyprctl workspaces -j 2>/dev/null)
active_workspace_id=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')

# Check if workspaces JSON is valid
if [ -z "$workspaces" ] || [ "$workspaces" = "[]" ]; then
    echo "(box :class \"workspaces\" :orientation \"h\" :space-evenly true :halign \"start\" :spacing 3 (eventbox :onhover \"eww update ws_hovered_id=$active_workspace_id\" :onhoverlost \"eww update ws_hovered_id=0\" (button :class \"workspace-btn active\" :onclick \"hyprctl dispatch workspace $active_workspace_id\" \"$active_workspace_id\")))"
    exit
fi

# Filter workspaces with windows > 0 or active workspace, and format as JSON
occupied_workspaces=$(echo "$workspaces" | jq --argjson active_id "$active_workspace_id" '
  sort_by(.id) |
  map(select(.windows > 0 or .id == $active_id) | {
    id: .id,
    occupied: (.windows > 0),
    active: (.id == $active_id)
  })
')

# Check if occupied_workspaces is empty
if [ $(echo "$occupied_workspaces" | jq 'length') -eq 0 ]; then
    echo "(box :class \"workspaces\" :orientation \"h\" :space-evenly true :halign \"start\" :spacing 3 (eventbox :onhover \"eww update ws_hovered_id=$active_workspace_id\" :onhoverlost \"eww update ws_hovered_id=0\" (button :class \"workspace-btn active\" :onclick \"hyprctl dispatch workspace $active_workspace_id\" \"$active_workspace_id\")))"
    exit
fi

# Get the current hovered workspace ID from EWW
hovered_id=$(eww get ws_hovered_id 2>/dev/null || echo 0)

# Generate Yuck widget structure
yuck_output=$(echo "$occupied_workspaces" | jq -r --argjson hovered_id "$hovered_id" '
  .[] |
  "(eventbox :onhover \"eww update ws_hovered_id=\(.id)\" :onhoverlost \"eww update ws_hovered_id=0\" (button :class \"workspace-btn" + (if .active then " active" else "" end) + (if .id == $hovered_id then " hovered" else "" end) + "\" :onclick \"hyprctl dispatch workspace \(.id)\" \"\(.id)\"))"
' | tr '\n' ' ')

# Wrap in a box widget
echo "(box :class \"workspaces\" :orientation \"h\" :space-evenly true :halign \"start\" :spacing 3 $yuck_output)"
