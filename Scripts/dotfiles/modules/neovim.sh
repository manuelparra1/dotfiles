#!/usr/bin/env bash
set -euo pipefail

banner "Neovim (${NVIM_CHANNEL})"

NVIM_DIR="${HOME}/Apps"
BIN_DIR="${HOME}/.bin"
NVIM_TGZ_URL=""
case "$NVIM_CHANNEL" in
  nightly) NVIM_TGZ_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz" ;;
  stable)  NVIM_TGZ_URL="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets[] | select(.name|test("nvim-linux-x86_64.tar.gz$")) | .browser_download_url')" ;;
  *) die "Unknown NVIM_CHANNEL: $NVIM_CHANNEL" ;;
esac

do_run mkdir -p "${NVIM_DIR}" "${BIN_DIR}"
TMP="$(mktemp -d)"
say "Downloading Neovim tarball: ${NVIM_TGZ_URL}"
do_run curl -fL "${NVIM_TGZ_URL}" -o "${TMP}/nvim.tar.gz"
do_run tar -xzf "${TMP}/nvim.tar.gz" -C "${TMP}"
# Move into versioned dir (overwrite previous install safely)
do_run rm -rf "${NVIM_DIR}/nvim"
do_run mv "${TMP}/nvim-linux-x86_64" "${NVIM_DIR}/nvim"

# Shim in ~/.bin
if [[ ! -e "${BIN_DIR}/nvim" ]]; then
  do_run ln -s "${NVIM_DIR}/nvim/bin/nvim" "${BIN_DIR}/nvim"
fi

# Deploy your Neovim config from repo
deploy_set ".config/nvim:${HOME}/.config/nvim"
say "Neovim installed and config deployed."
