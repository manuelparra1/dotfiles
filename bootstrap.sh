#!/usr/bin/env bash
set -euo pipefail

# ========= settings you likely want to tweak =========
DOTS="${HOME}/Github/dotfiles"       # where your repo lives
NVIM_CHANNEL="${NVIM_CHANNEL:-nightly}"  # nightly|stable (nightly fixes your dd issue)
NVIM_TARGET_DIR="${HOME}/Apps"       # full unpack goes here
BIN_DIR="${HOME}/.bin"               # put tiny shims/symlinks here
NODE_MODE="${NODE_MODE:-auto}"       # auto|nvm|system|skip  (auto = nvm only on Debian-like)
# =====================================================

# --- helpers ---
have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf "\033[1;36m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
die()  { printf "\033[1;31m[err]\033[0m %s\n" "$*"; exit 1; }

ensure_dirs() {
  mkdir -p "$BIN_DIR" "$NVIM_TARGET_DIR" "$HOME/.config"
  # ensure ~/.bin in PATH for zsh
  local line='export PATH="$HOME/.bin:$PATH"'
  if [ -f "$HOME/.zshrc" ] && ! grep -Fq "$line" "$HOME/.zshrc"; then
    printf '\n# ensure user bin on PATH\n%s\n' "$line" >> "$HOME/.zshrc"
  fi
}

detect_distro() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    DISTRO_ID="macos"; DISTRO_LIKE="macos"; return
  fi
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-}"; DISTRO_LIKE="${ID_LIKE:-}"
  else
    DISTRO_ID=""; DISTRO_LIKE=""
  fi
}
is_debian_like() { [[ "$DISTRO_ID" =~ (debian|ubuntu|pop) ]] || [[ "$DISTRO_LIKE" =~ (debian|ubuntu) ]]; }

pkg_install() { # $@: pkgs
  case "$DISTRO_ID" in
    macos) brew install "$@" ;;
    arch|artix) sudo pacman -Syu --needed --noconfirm "$@" ;;
    fedora) sudo dnf install -y "$@" ;;
    void) sudo xbps-install -Syu; sudo xbps-install -y "$@" ;;
    *) if is_debian_like; then sudo apt update; sudo apt install -y "$@"; else warn "unknown distro; install manually: $*"; fi ;;
  esac
}

# ---------- base packages ----------
install_base_packages() {
  log "Installing base CLI apps…"
  case "$DISTRO_ID" in
    macos)
      have brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      pkg_install eza bat syncthing zsh tmux ripgrep curl wget unzip gnu-tar node # node via brew on macOS
      ;;
    *)
      # common CLI
      pkg_install curl wget git unzip xz-utils tar ripgrep zsh tmux eza bat syncthing
      # DE/WM-agnostic clipboard + launchers (you’ve found these are needed everywhere)
      pkg_install xclip wl-clipboard
      # Wayland vs X11 app launcher
      if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        pkg_install wofi
      else
        pkg_install rofi
      fi
      ;;
  esac

  # starship (official installer keeps it current)
  if ! have starship; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
  # ensure starship in zsh
  local sline='eval "$(starship init zsh)"'
  if have starship && [ -f "$HOME/.zshrc" ] && ! grep -Fq "$sline" "$HOME/.zshrc"; then
    printf '\n# starship prompt\n%s\n' "$sline" >> "$HOME/.zshrc"
  fi

  # Debian sometimes ships `bat` as batcat; add a friendly alias if needed
  if is_debian_like && have batcat && ! have bat; then
    if ! grep -q 'alias bat=batcat' "$HOME/.zshrc" 2>/dev/null; then
      printf '\n# debian bat alias\nalias bat=batcat\n' >> "$HOME/.zshrc"
    fi
  fi
}

# ---------- Node.js ----------
install_node() {
  case "$NODE_MODE" in
    skip) log "Skipping Node.js"; return ;;
    nvm)  WANT="nvm" ;;
    system) WANT="system" ;;
    auto) WANT=$(is_debian_like && echo nvm || echo system) ;;
    *)    WANT="system" ;;
  esac

  if [[ "$WANT" = "nvm" ]]; then
    log "Installing Node via nvm (Debian-like preference)…"
    if [ ! -d "$HOME/.nvm" ]; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts

    nvm alias default 'lts/*'

    # ensure zsh loads nvm on login
    if ! grep -q 'NVM_DIR=.*/.nvm' "$HOME/.zshrc" 2>/dev/null; then
      {
        echo ''
        echo '# nvm'
        echo 'export NVM_DIR="$HOME/.nvm"'
        echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
      } >> "$HOME/.zshrc"
    fi

  else
    log "Installing Node via system package manager…"
    case "$DISTRO_ID" in
      macos) pkg_install node ;;
      arch|artix) pkg_install nodejs npm ;;
      fedora) pkg_install nodejs npm ;;
      void) pkg_install nodejs npm ;;
      *) pkg_install nodejs npm ;; # deb/ubuntu (if you forced system)
    esac
  fi
}

# ---------- Neovim from official tarball (into ~/Apps, shim at ~/.bin/nvim) ----------
install_nvim_tarball() {

  local channel="${1:-$NVIM_CHANNEL}"   # nightly|stable
  local os="$(uname -s)"
  local arch="$(uname -m)"
  local asset=""
  if [[ "$os" == "Darwin" ]]; then
    asset=$([[ "$arch" == "arm64" ]] && echo "nvim-macos-arm64.tar.gz" || echo "nvim-macos-x86_64.tar.gz")
  else
    # Linux
    asset=$([[ "$arch" =~ (aarch64|arm64) ]] && echo "nvim-linux-arm64.tar.gz" || echo "nvim-linux-x86_64.tar.gz")
  fi
  
  # Build correct GitHub URL
  local base="https://github.com/neovim/neovim/releases"
  local url
  if [[ "$channel" == "nightly" ]]; then
    url="${base}/download/nightly/${asset}"
  else
    url="${base}/latest/download/${asset}"
  fi
  
  log "Downloading Neovim ($channel) tarball…"
  local tmp; tmp="$(mktemp -d)"
  if ! curl -fL "$url" -o "$tmp/nvim.tgz"; then
    # Optional fallback for stable only: older-glibc builds
    if [[ "$channel" != "nightly" && "$os" != "Darwin" ]]; then
      local old="https://github.com/neovim/neovim-releases/releases/latest/download/${asset}"
      warn "Primary tarball failed; trying older-glibc build…"
      curl -fL "$old" -o "$tmp/nvim.tgz" || die "Failed to download Neovim tarball from both URLs."
    else
      die "Failed to download Neovim tarball."
    fi
  fi
  
  local stamp; stamp="$(date +%Y%m%d-%H%M)"
  local outdir="${NVIM_TARGET_DIR}/nvim-${channel}-${stamp}"
  mkdir -p "$outdir"
  tar -xzf "$tmp/nvim.tgz" -C "$outdir" --strip-components=1 || tar -xzf "$tmp/nvim.tgz" -C "$outdir"

  rm -f "${BIN_DIR}/nvim"
  ln -s "${outdir}/bin/nvim" "${BIN_DIR}/nvim"
  rm -rf "$tmp"

  log "Neovim ready: ${outdir}  (shim: ${BIN_DIR}/nvim)"
  "${BIN_DIR}/nvim" --version | head -n 3
}

# ---------- symlink dotfiles you care about right now ----------
link_dotfiles_core() {
  [ -d "$DOTS" ] || die "dotfiles repo not found at $DOTS"
  log "Linking core configs…"
  ln -snf "$DOTS/.config/nvim"        "$HOME/.config/nvim"
  ln -snf "$DOTS/.zshrc"              "$HOME/.zshrc"
  ln -snf "$DOTS/.tmux.conf"          "$HOME/.tmux.conf"
  ln -snf "$DOTS/.config/starship.toml" "$HOME/.config/starship.toml"

  # Optional — uncomment the ones you want now; add more as you expand:
  ln -snf "$DOTS/.config/kitty"     "$HOME/.config/kitty"
  ln -snf "$DOTS/.config/ghostty"   "$HOME/.config/ghostty"
  # ln -snf "$DOTS/.config/wofi"      "$HOME/.config/wofi"
  # ln -snf "$DOTS/.config/waybar"    "$HOME/.config/waybar"
  # ln -snf "$DOTS/.config/eww"       "$HOME/.config/eww"
  # ln -snf "$DOTS/.config/mpd"       "$HOME/.config/mpd"
  ln -snf "$DOTS/.fonts"            "$HOME/.fonts" && fc-cache -f
}

# ---------- (optional) secrets set-up with sops/age ----------
sops_optional_note() {
  if have sops; then
    log "sops is installed. If you keep an age key at ~/.config/sops/age/keys.txt, decrypt with: sops -d <file>"
  fi
}

# ---------- main ----------
main() {
  ensure_dirs
  detect_distro

  install_base_packages
  install_node
  install_nvim_tarball "$NVIM_CHANNEL"
  link_dotfiles_core
  sops_optional_note

  log "Done. Open a new shell so PATH/nvm/starship take effect, then run: nvim"
  echo "Tip: On Wayland Neovim uses wl-clipboard; on X11 it uses xclip for + register."
}

main "$@"
