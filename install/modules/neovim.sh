#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
# requires common.sh sourced by parent

# --- Neovim Module ---
# Downloads and installs Neovim from official tarballs.
# Supports stable, nightly, or specific versions.

# Allow overriding defaults via environment variables
: "${NVIM_CHANNEL:=stable}"  # stable | nightly | vX.Y.Z
: "${NVIM_PREFIX:=$HOME/Apps/nvim}"
: "${BIN_DIR:=$HOME/.local/bin}"

banner "Neovim (channel: ${NVIM_CHANNEL})"

# --- Preflight checks ---
have_dep() {
  have "$1" || die "Neovim module needs '$1', but it's not in PATH."
}
have_dep curl
have_dep tar
have_dep jq

if [[ "$(uname -s)" != "Linux" ]]; then
  die "This Neovim installer module currently supports Linux only."
fi
arch="$(uname -m)"
if [[ "$arch" != "x86_64" && "$arch" != "amd64" ]]; then
  die "This Neovim tarball is for x86_64 only. Your arch: $arch"
fi

# --- Resolve Download URL ---
REPO="neovim/neovim"
API_BASE="https://api.github.com/repos/${REPO}"
TARBALL="nvim-linux-x86_64.tar.gz"
URL=""
TAG=""

resolve_url() {
  say "Resolving Neovim download URL for channel: ${NVIM_CHANNEL}"
  case "$NVIM_CHANNEL" in
    nightly)
      TAG="nightly"
      URL="https://github.com/${REPO}/releases/download/nightly/${TARBALL}"
      ;;
    stable)
      json="$(do_run "curl -fsSL ${API_BASE}/releases/latest")"
      TAG="$(printf '%s' "$json" | jq -r '.tag_name')"
      URL="$(printf '%s' "$json" | jq -r --arg TB "$TARBALL" '.assets[] | select(.name == $TB) | .browser_download_url')"
      ;;
    v[0-9]*)
      TAG="$NVIM_CHANNEL"
      URL="https://github.com/${REPO}/releases/download/${TAG}/${TARBALL}"
      ;;
    *)
      die "Unknown NVIM_CHANNEL: '$NVIM_CHANNEL'. Use 'stable', 'nightly', or a tag like 'v0.9.5'."
      ;;
  esac

  if [[ -z "$TAG" || -z "$URL" || "$URL" == "null" ]]; then
    die "Could not resolve a download URL for tag '${TAG}'."
  fi
}

# --- Installation ---
install_neovim() {
  resolve_url
  say "Tag: ${TAG}, URL: ${URL}"

  do_run mkdir -p "${NVIM_PREFIX}" "${BIN_DIR}"
  local workdir; workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT

  say "Downloading to temporary directory..."
  do_run curl -fL --retry 3 -o "${workdir}/${TARBALL}" "${URL}"

  say "Extracting..."
  do_run tar -C "$workdir" -xzf "${workdir}/${TARBALL}"

  local src_dir="${workdir}/nvim-linux-x86_64"
  if [[ ! -x "${src_dir}/bin/nvim" ]]; then
    die "nvim binary not found after extraction."
  fi

  local target_dir="${NVIM_PREFIX}/${TAG}"
  say "Installing to ${target_dir}"
  if [[ -e "$target_dir" ]]; then
    local ts; ts=$(date +%Y%m%d-%H%M%S)
    say "Backing up existing version at ${target_dir} -> ${target_dir}.bak-${ts}"
    do_run mv "$target_dir" "${target_dir}.bak-${ts}"
  fi
  do_run mkdir -p "$target_dir"
  # Use cp and not mv to avoid issues with tmpfs across different mounts
  do_run cp -a "${src_dir}/." "${target_dir}/"

  local shim_path="${BIN_DIR}/nvim"
  say "Creating shim at ${shim_path}"
  # A symlink is simpler and generally fine.
  do_run ln -sf "${target_dir}/bin/nvim" "${shim_path}"

  say "Neovim (${TAG}) installed successfully."
  do_run "${shim_path}" --version | head -n 1
}

# --- Deploy Config ---
deploy_nvim_config() {
  if [[ -d "${REPO_ROOT}/.config/nvim" ]]; then
    say "Deploying Neovim config"
    deploy_set ".config/nvim:${HOME}/.config/nvim"
  else
    warn "No '.config/nvim' directory found in repo to deploy."
  fi
}

# --- Main module execution ---
install_neovim
deploy_nvim_config
say "Neovim module complete."