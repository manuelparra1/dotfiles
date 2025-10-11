#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/manuelparra1/dotfiles.git}"
TARGE T_DIR="${HOME}/.local/share/dotfiles"

# --- Helper functions ---
say() { printf "\033[1;36m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
die() { printf "\033[1;31m[err]\033[0m %s\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- Preflight Check: Ensure Git is installed ---
ensure_git() {
  if have git; then
    say "Git is installed."
    return
  fi

  warn "Git not found. Attempting to install..."
  local PKM_CMD=""
  if have apt-get; then
    PKM_CMD="sudo apt-get update && sudo apt-get install -y git"
  elif have dnf; then
    PKM_CMD="sudo dnf install -y git"
  elif have pacman; then
    PKM_CMD="sudo pacman -Sy --noconfirm git"
  elif have zypper; then
    PKM_CMD="sudo zypper install -y git"
  elif have brew; then
    PKM_CMD="brew install git"
  else
    die "Could not find a supported package manager (apt, dnf, pacman, zypper, brew) to install Git. Please install Git manually and re-run this script."
  fi

  say "Running: ${PKM_CMD}"
  if ! eval "${PKM_CMD}"; then
    die "Failed to install Git. Please install it manually and re-run this script."
  fi
}

# --- Main execution ---
ensure_git

say "Cloning dotfiles repository..."
mkdir -p "$(dirname "$TARGET_DIR")"

if [[ -d "$TARGET_DIR/.git" ]]; then
  say "Updating existing dotfiles in ${TARGET_DIR}..."
  git -C "$TARGET_DIR" pull --ff-only
else
  say "Cloning into ${TARGET_DIR}..."
  git clone --depth 1 "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
say "Launching main installer..."
chmod +x ./install_dotfiles.sh
./install_dotfiles.sh