#!/bin/bash

# This script combines all markdown files in the current directory
# and its subdirectories into a single file called output.md.
# It adds separator lines between each file's contents.

set -euo pipefail

output_file="output.md"
tmp="$(mktemp)"

printf "# Combined Markdown Files\n\n" > "$tmp"

# -not -name prevents the feedback loop
find . -type f -name "*.md" -not -name "$output_file" -print0 |
  sort -z |
  while IFS= read -r -d '' file; do
    printf '## `%s`\n---\n```markdown\n' "${file#./}" >> "$tmp"
    cat "$file" >> "$tmp"
    printf '\n```\n\n' >> "$tmp"
  done

mv "$tmp" "$output_file"
