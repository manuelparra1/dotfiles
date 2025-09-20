#!/bin/bash

# A script to find and fix video file references in markdown files.
# It updates old naming schemes (e.g., '1 - ...' or '10 - ...')
# to a new three-digit padded format (e.g., '001 - ...' or '010 - ...').

echo "Starting search for markdown files to update..."

# Use 'find' to locate all .md files and process them one by one.
# The -print0 and 'while read -d' construct handles filenames with spaces or newlines gracefully.
find . -type f -name "*.md" -print0 | while IFS= read -r -d $'\0' md_file; do

  # Store the original content to check for changes later
  original_content=$(<"$md_file")
  
  # --- Perform Replacements in Memory ---

  # Pass 1: Fix double-digit numbers (e.g., "10 - " -> "010 - ").
  #         This must run first. The `\b` is a word boundary to ensure we only 
  #         match standalone numbers like "10" and not part of "110".
  modified_content=$(echo "$original_content" | sed -E 's/\b([0-9]{2}) - /0\1 - /g')
  
  # Pass 2: Fix single-digit numbers (e.g., "1 - " -> "001 - ").
  #         We pipe the result from the first pass into this one.
  modified_content=$(echo "$modified_content" | sed -E 's/\b([0-9]) - /00\1 - /g')
  
  # Compare the final content with the original.
  if [[ "$original_content" != "$modified_content" ]]; then
    echo "Updating references in: $md_file"
    # If there's a difference, overwrite the original file with the new content.
    # The -n flag prevents echo from adding an extra newline at the end.
    echo -n "$modified_content" > "$md_file"
  fi
  
done

echo "Update process complete."
