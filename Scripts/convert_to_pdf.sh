#!/bin/bash

# Check if a filename argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: \$0 <markdown_file>"
    exit 1
fi

# Get the input filename
input_file="$1"

# Define the theme template
theme="orangeheart"

# Define the absolute path to the template file
template_file="/opt/homebrew/opt/pandoc/share/pandoc/templates/$theme.tex"

# Define the output filename
output_file="${input_file%.md}.pdf"

# Convert Markdown to PDF using Pandoc
pandoc --pdf-engine=xelatex -f markdown -t pdf --template="$template_file" "$input_file" -o "$output_file"

echo "Conversion complete. Output file: $output_file"
