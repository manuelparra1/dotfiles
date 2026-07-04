#!/usr/bin/env bash

# Input validation
if [ $# -eq 0 ]; then
    echo "Error: No file specified" >&2
    echo "Usage: $0 <markdown-file>" >&2
    exit 1
fi

input_file="$1"

# Check if file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found" >&2
    exit 1
fi

# Check if file is readable
if [ ! -r "$input_file" ]; then
    echo "Error: File '$input_file' is not readable" >&2
    exit 1
fi

# Warn if not .md extension (but continue)
if [[ ! "$input_file" =~ \.md$ ]]; then
    echo "Warning: '$input_file' doesn't have .md extension" >&2
fi

# Generate output filename
base_name="${input_file%.md}"
output_file="${base_name}_headings.md"

# Check if output file already exists
if [ -f "$output_file" ]; then
    read -p "Warning: '$output_file' exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
fi

# Extract headings
if ! grep '^#' "$input_file" > "$output_file"; then
    echo "Error: Failed to extract headings" >&2
    rm -f "$output_file"  # Clean up empty file
    exit 1
fi

# Check if any headings were found
if [ ! -s "$output_file" ]; then
    echo "Warning: No headings found in '$input_file'" >&2
    rm -f "$output_file"
    exit 0
fi

echo "Success: Headings extracted to '$output_file'"
