#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
# Module: user scripts, helpers, and app shims
# Copies repo ./Scripts -> ~/Scripts and sets up ~/Apps + ~/.bin
# Expects: say, warn, do_run, deploy, REPO_ROOT, MODE
set -euo pipefail

banner "User Scripts & App helpers"

# --- ensure ~/Scripts, ~/.bin, ~/Apps exist ---
for d in "${HOME}/Scripts" "${HOME}/.local/bin" "${HOME}/Apps"; do
  [[ -d "$d" ]] || do_run mkdir -p "$d"
done

# --- Deploy your repo Scripts directory ---
if [[ -d "${REPO_ROOT}/Scripts" ]]; then
  # Always use rsync for this to prevent symlink loops, which are dangerous
  # for a directory that might be a parent of the repo itself.
  say "Deploying your repo Scripts folder to ~/Scripts using rsync"
  do_run rsync -a --delete "${REPO_ROOT}/Scripts/" "${HOME}/Scripts/"
else
  warn "No ./Scripts directory found in repo."
fi

# --- ensure all files in ~/Scripts are executable ---
if [[ -d "${HOME}/Scripts" ]]; then
  say "Ensuring all user scripts are executable"
  # We exclude dotfiles and non-executable formats.
  do_run find "${HOME}/Scripts" -type f ! -name '.*' ! -name '*.md' ! -name '*.txt' -exec chmod +x {} \;
fi

# --- optional: link each script in a dedicated bin folder to ~/.local/bin ---
# This is a common pattern for scripts intended to be on the PATH.
if [[ -d "${HOME}/Scripts/bin" ]]; then
  say "Linking executables from ~/Scripts/bin into ~/.local/bin"
  for f in "${HOME}/Scripts/bin/"*; do
    [[ -f "$f" && -x "$f" ]] || continue
    dest="${HOME}/.local/bin/$(basename "$f")"
    do_run ln -sf "$f" "$dest"
  done
fi

# --- ensure ~/.local/bin is on PATH (in .zshrc) ---
# This is handled by the zsh module, so we don't need to do it here.

# --- optional: look for .desktop templates under Scripts/applications/ ---
# Use this to autoinstall launchers for apps you store in ~/Apps
if [[ -d "${REPO_ROOT}/Scripts/applications" ]]; then
  dest="${HOME}/.local/share/applications"
  do_run mkdir -p "$dest"
  say "Deploying custom .desktop entries to $dest"
  do_run rsync -a --delete "${REPO_ROOT}/Scripts/applications/" "$dest/"
fi

say "Scripts module complete."
