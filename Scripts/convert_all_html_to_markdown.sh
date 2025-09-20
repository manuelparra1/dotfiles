#!/bin/bash
# Convert all HTML files in the current directory to Markdown

for html_file in *.html; do
    [[ -e "$html_file" ]] || continue
    md_file="${html_file%.html}.md"
    # Skip conversion if the markdown file already exists
    [[ -e "$md_file" ]] && { echo "Skipping $html_file: $md_file already exists."; continue; }
    ~/Scripts/html_to_md.py "$html_file"
done

# `-e` is a test operator that returns true if the specified file exists (whether it’s a regular file, directory, or any other type). In the script, `[[ -e "$html_file" ]]` checks that the `html_file` actually exists before proceeding.
# `md_file="${html_file%.html}.md"` uses Bash parameter expansion.
# The `${html_file%.html}` part removes the shortest trailing `.html` suffix from the value of `html_file`.
# Then `.md` is appended, so the resulting string is the original filename with its `.html` extension replaced by `.md`. The result is assigned to the variable `md_file`.
