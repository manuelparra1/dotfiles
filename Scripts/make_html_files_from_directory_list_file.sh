#!/bin/bash

# Define the input file containing the directory names
INPUT_FILE="directories.txt"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file '$INPUT_FILE' not found."
  exit 1
fi

echo "Creating HTML files based on '$INPUT_FILE'..."

# Read each line from the input file
while IFS= read -r line; do
  # Remove leading/trailing whitespace from the line
  trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # Check if the line is not empty
  if [ -n "$trimmed_line" ]; then
    # Construct the filename by appending .html
    filename="${trimmed_line}.html"

    # Create an empty file with the constructed name
    touch "$filename"
    echo "Created: $filename"
  fi
done < "$INPUT_FILE"

echo "All specified HTML files have been created."
