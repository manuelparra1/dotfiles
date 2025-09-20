#!/bin/bash

# This script combines all files in the current directory
# and its subdirectories into a single file called output.md.
# It adds separator lines between each file's contents.

output_file="output.md"

# Initialize the output file
echo "# Combined Files" > "$output_file"
echo "" >> "$output_file"

# Find all files and process them
find . -type f ! -name "$output_file" -print0 | while IFS= read -r -d '' file; do
  # Output separator lines and file name to output.md
  echo "## \`${file#./}\`" >> "$output_file"
  echo "---" >> "$output_file"

  # Output contents of each file, wrapped in ```text
  echo '```text' >> "$output_file"
  cat "$file" >> "$output_file"
  echo '```' >> "$output_file"
  echo "" >> "$output_file"
done


