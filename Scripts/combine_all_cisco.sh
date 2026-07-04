#!/bin/bash

# This script combines all .cisco files in the current directory
# and its subdirectories into a single Markdown file.
# Each file's content is placed in a code block with appropriate syntax highlighting.

output_file="combined_cisco_configs.md"

# Check if there are any .cisco files
if ! find . -type f -name "*.cisco" | grep -q .; then
  echo "No .cisco files found in the current directory or subdirectories."
  exit 1
fi

# Initialize the output file
echo "# Combined Cisco Configuration Files" > "$output_file"
echo "" >> "$output_file"
echo "This document contains all \`.cisco\` files found in the directory tree." >> "$output_file"
echo "" >> "$output_file"

# Find all .cisco files and process them
find . -type f -name "*.cisco" -print0 | sort -z | while IFS= read -r -d '' file; do
  # Skip the output file itself if it's somehow matched (unlikely, but safe)
  [[ "$file" == "./$output_file" ]] && continue

  # Get a clean relative path for display
  relative_path="${file#./}"

  # Add section header with the file path
  echo "## File: \`$relative_path\`" >> "$output_file"
  echo "" >> "$output_file"

  # Add the code block with Cisco/IOS-like syntax highlighting
  # Markdown commonly uses ```cisco, ```ios, or ```text for config files
  echo '```ios' >> "$output_file"
  cat "$file" >> "$output_file"
  echo '```' >> "$output_file"
  echo "" >> "$output_file"

  # Optional: add a horizontal ruler between files for better visual separation
  echo "---" >> "$output_file"
  echo "" >> "$output_file"
done

echo "All .cisco files have been combined into '$output_file'."
