#!/bin/bash

# Base directory
BASE_DIR="/home/dusts/aston"

# Navigate to the base directory
cd "$BASE_DIR" || { echo "Directory not found: $BASE_DIR"; exit 1; }

# Create target directories (Monday-Friday)
for day in Monday Tuesday Wednesday Thursday Friday; do
    mkdir -p "$day"
done

# Process .md files using find
find . -type f -name "*.md" -exec bash -c '
for file; do
    # Get access time and modification time (in seconds since epoch)
    atime=$(stat -c %X "$file")
    mtime=$(stat -c %Y "$file")
    
    # Use the oldest timestamp as the inferred creation date
    if [ "$atime" -le "$mtime" ]; then
        inferred_time="$atime"
    else
        inferred_time="$mtime"
    fi

    # Determine the day of the week from the inferred time
    dow=$(date -d @"$inferred_time" +%A)
    
    # Map Saturday and Sunday to Wednesday
    case "$dow" in
        Saturday|Sunday)
            target="Wednesday"
            ;;
        *)
            target="$dow"
            ;;
    esac
    
    # Copy the file to the appropriate directory
    cp "$file" "$target/"
done
' bash {} +
