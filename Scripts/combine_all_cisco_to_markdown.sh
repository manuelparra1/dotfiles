#!/bin/sh

# This script will find all cisco files
# in the current directory and combine them
# into a single file called output.md
# it will wrap the contents in ```cisco code
# block

# Find all Cisco files loop through them and combine them into a single file

echo "# Combined Cisco Configurations" > output.md
for file in *.cisco; do
  echo "## \`$file\`" >> output.md
  echo "\`\`\`cisco" >> output.md
  cat "$file" >> output.md
  echo "\`\`\`" >> output.md
  echo >> output.md
  echo "---" >> output.md
done
