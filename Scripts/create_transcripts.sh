#!/bin/bash

# A script to automate the creation of text files from clipboard content
# for corresponding .mp4 files in the current directory.

echo "Starting transcript creation process..."
echo "-------------------------------------"

# Loop through all files ending in .mp4 in the current directory
for video_file in *.mp4; do
  # Get the filename without the .mp4 extension
  base_name="${video_file%.mp4}"
  
  # Define the potential names for the transcript file
  text_file="${base_name}.txt"
  md_file="${base_name}.md"

  # Check if a .txt or .md file with the same base name already exists
  if [[ -f "$text_file" || -f "$md_file" ]]; then
    # If it exists, print a message and skip to the next video
    echo "☑ Skipping '${video_file}': Transcript already exists."
  else
    # If no transcript exists, begin the monitoring process
    echo ""
    echo "▶ Waiting for clipboard update for:"
    echo "  '${video_file}'"
    echo "  Copy the transcript text now. A new file named '${text_file}' will be created."
    echo ""

    # Store the initial content of the clipboard to detect a change
    # The `-n` or `--no-newline` flag is used to avoid issues with trailing newlines
    initial_clipboard=$(wl-paste -n)

    # Loop indefinitely until the clipboard content changes
    while true; do
      current_clipboard=$(wl-paste -n)
      
      # Compare the current clipboard content with the initial content
      if [[ "$current_clipboard" != "$initial_clipboard" ]]; then
        echo "  Clipboard updated! Saving content to '${text_file}'..."
        
        # Save the new clipboard content to the text file
        # We use `wl-paste` again here to get the full content with newlines
        wl-paste > "$text_file"
        
        echo "  ✔ Saved."
        # Break out of the inner 'while' loop to proceed to the next .mp4 file
        break 
      fi
      
      # Wait for 1 second before checking again to avoid excessive CPU usage
      sleep 1
    done
  fi
done

echo ""
echo "---------------------------------------------"
echo "🎉 All done! No more MP4 files are missing transcripts."
echo "---------------------------------------------"
