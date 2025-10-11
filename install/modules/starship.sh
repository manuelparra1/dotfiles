#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
# requires common.sh sourced by parent

banner "Starship Prompt"

# --- Install Starship ---
if ! have starship; then
  say "Installing Starship..."
  # The official installer is the most robust method
  do_run curl -fsSL https://starship.rs/install.sh | sh -s -- -y
else
  say "Starship is already installed."
fi

# --- Deploy Config ---
if [[ -f "${REPO_ROOT}/.config/starship.toml" ]]; then
  say "Deploying Starship config"
  deploy_set ".config/starship.toml:${HOME}/.config/starship.toml"
else
  warn "No '.config/starship.toml' file found in repo to deploy."
fi

# --- Ensure Starship is initialized in .zshrc ---
ZSHRC_PATH="${HOME}/.zshrc"
STARSHIP_INIT_LINE='eval "$(starship init zsh)"'
if [[ -f "$ZSHRC_PATH" ]]; then
  if ! grep -Fxq "$STARSHIP_INIT_LINE" "$ZSHRC_PATH"; then
    say "Adding Starship init to .zshrc"
    do_run "printf '\n# Initialize Starship Prompt\n%s\n' '$STARSHIP_INIT_LINE' >> '$ZSHRC_PATH'"
  fi
else
  warn "Could not find .zshrc to add starship init line."
fi

say "Starship module complete."
