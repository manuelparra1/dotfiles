#!/bin/bash
# rsync_merge.sh

# Check if source and target directories are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source-directory> <target-directory>"
    exit 1
fi

# Remove trailing slashes from source and target directories
source_dir="${1%/}"
target_dir="${2%/}"

# Check if source directory exists
if [ ! -d "$source_dir" ]; then
    echo "Source directory '$source_dir' not found."
    exit 1
fi

# Check if target directory exists
if [ ! -d "$target_dir" ]; then
    echo "Target directory '$target_dir' not found."
    exit 1
fi

# Perform rsync
rsync -rvh --progress --append --partial --ignore-existing "$source_dir/" "$target_dir/"
