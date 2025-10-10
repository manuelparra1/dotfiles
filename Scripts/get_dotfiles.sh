#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/manuelparra1/dotfiles.git}"
TARGET_DIR="${HOME}/.local/share/dotfiles"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1; please install it first."; exit 1; }; }
need git

mkdir -p "$(dirname "$TARGET_DIR")"

if [[ -d "$TARGET_DIR/.git" ]]; then
  echo "Updating existing dotfiles in ${TARGET_DIR}..."
  git -C "$TARGET_DIR" pull --ff-only
else
  echo "Cloning into ${TARGET_DIR}..."
  git clone --depth 1 "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
chmod +x ./install_dotfiles
./install_dotfiles.sh
