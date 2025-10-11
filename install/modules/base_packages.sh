#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
# requires common.sh sourced by parent

banner "Base packages"

# Core CLI set used by your repo structure
pkg_install git curl unzip jq fzf ripgrep fd bat zsh stow make python3 pipx

# uv (Python toolchain) — official installer handles paths
if ! have uv; then
  say "Installing uv"
  do_run curl -LsSf https://astral.sh/uv/install.sh | sh
  # ensure ~/.local/bin in PATH for current session
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# nvm/node (default to nvm on Debian-like; system node on Arch is acceptable)
if [[ "${PKM}" == "apt" || "${NODE_MODE:-nvm}" == "nvm" ]]; then
  if [[ ! -d "${HOME}/.nvm" ]]; then
    say "Installing nvm"
    do_run curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
  # shellcheck disable=SC1090
  do_run 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm install --lts; nvm alias default lts/*'
elif [[ "${PKM}" == "pacman" ]]; then
  pkg_install node  # nodejs npm
fi

# Create uv-related directories you asked for
for p in "${HOME}/Environments" "${HOME}/.cache/uv" "${HOME}/.config/uv" "${HOME}/.local/share/uv"; do
  [[ -d "$p" ]] || do_run mkdir -p "$p"
done
