#!/bin/bash

# This script renames files by adding zero-padding to the numeric part of the filename.
# It ensures that numbers have a consistent number of digits for better sorting and organization.

# Example:
# Before: aws_1.md, aws_10.md, aws_2.md
# After:  aws_001.md, aws_002.md, aws_010.md
#
# Usage: ./zero_pad_filenames.sh <prefix> [pad_length]
# Example: ./zero_pad_filenames.sh aws_ 3  # Pads numbers to 3 digits (aws_1.md → aws_001.md)

# Store the first argument as the prefix (e.g., "aws_")
prefix="$1"

# Store the second argument as the padding length (e.g., "3" for aws_001.md).
# If the user doesn't provide a second argument, default to 3.
pad_length="${2:-3}" # The "${2:-3}" syntax means "use $2 if set, otherwise use 3"

# If no prefix is provided, print usage instructions and exit
if [[ -z "$prefix" ]]; then
  echo "Usage: $0 <prefix> [pad_length]"
  echo "Example: $0 aws_ 3   # Renames aws_1.md → aws_001.md"
  exit 1  # Exit with an error status (1 means failure)
fi

# Loop through all files that start with the given prefix, followed by any characters, and have an extension
for file in ${prefix}*.*; do
  
  # Use regular expressions to extract the parts of the filename:
  # - ^(${prefix}) → Captures the prefix (e.g., "aws_")
  # - ([0-9]+) → Captures the numeric portion of the filename (e.g., "52" in "aws_52.md")
  # - (\..+)$ → Captures the file extension (e.g., ".md")
  if [[ $file =~ ^(${prefix})([0-9]+)(\..+)$ ]]; then
    
    num="${BASH_REMATCH[2]}"  # Extract the numeric part from the matched filename
    ext="${BASH_REMATCH[3]}"  # Extract the file extension

    # Use printf to format the number with leading zeros (e.g., "52" → "052" if pad_length=3)
    new_num=$(printf "%0${pad_length}d" "$num")

    # Construct the new filename using the prefix, zero-padded number, and original extension
    new_name="${prefix}${new_num}${ext}"

    # Check if the new name is different from the old name (to avoid unnecessary renaming)
    if [[ "$file" != "$new_name" ]]; then
      mv "$file" "$new_name"  # Rename the file
      echo "Renamed: $file → $new_name"  # Print what was renamed for confirmation
    fi
  fi
done
