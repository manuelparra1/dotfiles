#!/bin/bash

# Get the JSON tree of all windows/containers from i3
tree=$(i3-msg -t get_tree)

# Use jq to find the focused window/container and extract its name (title)
# The '..' recursively searches the JSON.
# 'select(.focused?)' selects the object where the 'focused' key is true.
# '.name // ""' gets the value of the 'name' key, or an empty string if null/missing.
title=$(echo "$tree" | jq -r '.. | select(.focused?) | .name // ""')

# Optional: Truncate the title if it's too long for your bar
max_len=60 # Adjust this number to your preference
if [[ ${#title} -gt $max_len ]]; then
  title="${title:0:$((max_len-3))}..." # Add ellipsis "..."
fi

# Output the title for i3blocks
echo "$title"

# Exit successfully
exit 0
