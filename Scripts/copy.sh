#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage: rsync_copy.sh SOURCE DESTINATION

Copies SOURCE to DESTINATION using rsync with resume support.
EOF
  exit 2
}

trap 'die "Command failed (exit=$?) on line $LINENO: $BASH_COMMAND"' ERR

[[ $# -eq 2 ]] || usage

src=$1
dest=$2

[[ -n "$src" ]] || die "SOURCE is empty"
[[ -n "$dest" ]] || die "DESTINATION is empty"

command -v rsync >/dev/null 2>&1 || die "rsync not found in PATH"

# Basic source validation (local paths only)
if [[ "$src" != *:* ]]; then
  [[ -e "$src" ]] || die "SOURCE does not exist: $src"
  [[ -r "$src" ]] || die "SOURCE is not readable: $src"
fi

# Destination validation/creation (local paths only)
if [[ "$dest" != *:* ]]; then
  # If dest ends with / or is an existing directory, ensure it exists
  if [[ "$dest" == */ || -d "$dest" ]]; then
    mkdir -p -- "$dest" || die "Failed to create destination directory: $dest"
  else
    # Ensure parent directory exists for file destinations
    parent_dir=$(dirname -- "$dest")
    mkdir -p -- "$parent_dir" || die "Failed to create destination parent directory: $parent_dir"
  fi

  [[ -w "$dest" || -w "$(dirname -- "$dest")" ]] || die "DESTINATION is not writable: $dest"
fi

# Prevent obvious no-op when both are identical local paths
if [[ "$src" != *:* && "$dest" != *:* && "$src" == "$dest" ]]; then
  die "SOURCE and DESTINATION are the same path: $src"
fi

rsync -avh \
  --info=progress2 \
  --partial \
  --append-verify \
  --update \
  -- "$src" "$dest"
