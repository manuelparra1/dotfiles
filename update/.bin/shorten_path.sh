#!/bin/bash

# Remove trailing slash if present
path="${1%/}"

# Count the number of directories
dir_count=$(echo "$path" | tr -cd '/' | wc -c)

if [ "$dir_count" -gt 2 ]; then
    # Extract the last two directories
    last_two=$(echo "$path" | rev | cut -d'/' -f1-2 | rev)
    echo ".../$last_two"
else
    # If there are 2 or fewer directories, show the full path
    echo "$path"
fi
