#!/usr/bin/env bash
# Module: user scripts, helpers, and app shims
# Copies repo ./Scripts -> ~/Scripts and sets up ~/Apps + ~/.bin
# Expects: say, warn, do_run, deploy, REPO_ROOT, MODE
set -euo pipefail

banner "User Scripts & App helpers"

# --- ensure ~/Scripts, ~/.bin, ~/Apps exist ---
for d in "${HOME}/Scripts" "${HOME}/.bin" "${HOME}/Apps"; do
  [[ -d "$d" ]] || do_run mkdir -p "$d"
done

# --- copy or link your repo Scripts directory ---
if [[ -d "${REPO_ROOT}/Scripts" ]]; then
  say "Deploying your repo Scripts folder to ~/Scripts"
  if [[ "${MODE}" == "copy" ]]; then
    do_run rsync -a --delete "${REPO_ROOT}/Scripts/" "${HOME}/Scripts/"
  else
    # link entire dir if not already linked
    if [[ -L "${HOME}/Scripts" ]]; then
      say "~/Scripts already linked."
    else
      do_run ln -sfn "${REPO_ROOT}/Scripts" "${HOME}/Scripts"
    fi
  fi
else
  warn "No ./Scripts directory found in repo."
fi

# --- ensure all files in ~/Scripts are executable ---
if [[ -d "${HOME}/Scripts" ]]; then
  say "Ensuring all user scripts are executable"
  do_run find "${HOME}/Scripts" -type f ! -name "*.md" -exec chmod +x {} \;
fi

# --- optional: link each script in ~/Scripts/bin to ~/.bin ---
# If you keep reusable scripts in ~/Scripts/bin (for PATH)
if [[ -d "${HOME}/Scripts/bin" ]]; then
  say "Linking ~/Scripts/bin scripts into ~/.bin"
  for f in "${HOME}/Scripts/bin/"*; do
    [[ -f "$f" ]] || continue
    local dest="${HOME}/.bin/$(basename "$f")"
    do_run ln -sf "$f" "$dest"
  done
fi

# --- ensure ~/.bin is on PATH (in .zshrc) ---
if [[ -f "${HOME}/.zshrc" ]]; then
  if ! grep -q '.bin' "${HOME}/.zshrc"; then
    say "Appending ~/.bin to PATH in .zshrc"
    do_run bash -c 'echo '\''export PATH="$HOME/.bin:$PATH"'\'' >> "$HOME/.zshrc"'
  fi
fi

# --- optional: look for .desktop templates under Scripts/applications/ ---
# Use this to autoinstall launchers for apps you store in ~/Apps
if [[ -d "${REPO_ROOT}/Scripts/applications" ]]; then
  local dest="${HOME}/.local/share/applications"
  do_run mkdir -p "$dest"
  say "Deploying custom .desktop entries to $dest"
  do_run rsync -a --delete "${REPO_ROOT}/Scripts/applications/" "$dest/"
fi

say "Scripts module complete."

