#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Dotfiles Installer (interactive + modular)
# ============================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_DIR="${HOME}/.local/share/dotfiles"
MODULES_DIR_REL="install/modules"
MODULES_DIR="${REPO_ROOT}/${MODULES_DIR_REL}"

DEFAULT_MODE="link"   # link|copy
MODE="${DEFAULT_MODE}"
DRY=0
ALL_FLAG=0
NVIM_CHANNEL="${NVIM_CHANNEL:-stable}"   # default stable per your preference
REQUESTED_MODULES=()

# ---------- tiny logger ----------
say()   { printf "\033[1;36m==>\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
die()   { printf "\033[1;31m[err]\033[0m %s\n" "$*" >&2; exit 1; }
banner(){ printf "\n\033[1;35m==== %s ====\033[0m\n" "$*"; }

do_run() {
  if [[ "${DRY}" -eq 1 ]]; then
    printf "[dry] %s\n" "$*"
  else
    eval "$@"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

resolve_path() {
  local target="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$target"
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$target" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
    return
  fi
  if command -v python >/dev/null 2>&1; then
    python - "$target" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
    return
  fi
  # Fallback: use a subshell to resolve relative paths
  (cd "$(dirname "$target")" 2>/dev/null && printf '%s\n' "$(pwd)/$(basename "$target")")
}

# ---------- Usage ----------
usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [modules...]

Modules:
  base          Install base tools + uv dirs, etc.
  neovim        Install Neovim (stable by default) + config
  zsh           Install Zsh + .zshrc + plugins/customizations
  starship      Install Starship prompt + config
  scripts       Copy repo ./Scripts -> ~/Scripts (common scripts)
  secrets       Install sops and decrypt secrets.yaml
  edit-secrets  Decrypt and open secrets.yaml for editing
  backup        Create a full backup of existing dotfiles
  uninstall     Remove all installed dotfiles and configurations
  all           Run all of the above (excluding edit-secrets, uninstall, backup)

Options:
  --all                 Install everything (excluding edit-secrets, uninstall, backup)
  --neovim-nightly      Force Neovim nightly
  --neovim-stable       Force Neovim stable (default)
  --mode link|copy      Deploy method (default: link; prompts if not set)
  --dry-run             Print what would happen
  -h, --help            Show help

No args -> interactive menu + friendly mode prompt
Examples:
  ./install_dotfiles --all
  ./install_dotfiles --all --neovim-nightly
  ./install_dotfiles neovim zsh
  ./install_dotfiles               # interactive
EOF
}

# ---------- Arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL_FLAG=1 ;;
    all) REQUESTED_MODULES=(base neovim zsh starship scripts secrets) ;;
    base|neovim|zsh|starship|scripts|secrets|edit-secrets|uninstall|backup) REQUESTED_MODULES+=("$1") ;;
    --neovim-nightly) NVIM_CHANNEL="nightly" ;;
    --neovim-stable)  NVIM_CHANNEL="stable" ;;
    --mode) MODE="${2:-link}"; shift ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
  shift
done

# ---------- Offer to standardize repo location ----------
standardize_location() {
  if [[ "${REPO_ROOT}" != "${STD_DIR}" ]]; then
    echo
    echo "Recommended location for this repo: ${STD_DIR}"
    read -r -p "Move repo there and relaunch installer? (Y/n): " ans
    case "${ans:-Y}" in
      [nN]*) return 0 ;;
      *)  do_run mkdir -p "$(dirname "${STD_DIR}")"
          # rsync preserves perms, hidden files, etc.
          do_run rsync -a --delete "${REPO_ROOT}/" "${STD_DIR}/"
          say "Relaunching from ${STD_DIR} …"
          # Optional: offer to remove old location (safety prompt)
          read -r -p "Delete old location '${REPO_ROOT}'? (y/N): " del
          if [[ "${del:-N}" =~ ^[yY]$ ]]; then
            do_run rm -rf "${REPO_ROOT}"
          fi
          exec "${STD_DIR}/install_dotfiles.sh" "$@"
          ;;
    esac
  fi
}

# Relaunch from standard location if needed
standardize_location "$@"

# Refresh variables after possible relaunch
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${REPO_ROOT}/${MODULES_DIR_REL}"

# ---------- Interactive menu ----------
interactive_menu() {
  say "Interactive mode"
  local picks=()
  if have fzf; then
    local choice
    choice="$(
      printf "backup\tBackup existing dotfiles\nbase\tBase tools + uv\nneovim\tNeovim + config\nzsh\tZsh + .zshrc\nstarship\tStarship prompt + config\nscripts\tCopy ./Scripts to ~/Scripts\nsecrets\tDecrypt secrets file\nedit-secrets\tEdit the secrets file\nuninstall\tRemove all dotfiles configs\n" \
        | column -t -s $'\t' \
        | fzf --multi --prompt="Select modules (TAB multi-select, ENTER confirm): " \
              --header="ESC cancels" \
        | awk '{print $1}'
    )" || true
    [[ -z "$choice" ]] && { warn "No selection made; exiting."; exit 1; }
    mapfile -t picks <<<"$choice"
    if printf '%s\n' "${picks[@]}" | grep -qx 'neovim'; then
      local ch
      ch="$(printf "stable\nnightly\n" | fzf --prompt="Neovim channel: ")"
      NVIM_CHANNEL="${ch:-stable}"
    fi
  else
    # Simple fallback
    local opts=("backup" "base" "neovim" "zsh" "starship" "scripts" "secrets" "edit-secrets" "uninstall" "done")
    while :; do
      echo "Add a module (type number):"
      local i=1; for o in "${opts[@]}"; do echo "  $i) $o"; ((i++)); done
      read -r -p "> " ans
      case "$ans" in
        1) picks+=("backup") ;;
        2) picks+=("base") ;;
        3) picks+=("neovim"); read -r -p "Neovim channel [stable/nightly] (default: stable): " ch; NVIM_CHANNEL="${ch:-stable}" ;;
        4) picks+=("zsh") ;;
        5) picks+=("starship") ;;
        6) picks+=("scripts") ;;
        7) picks+=("secrets") ;;
        8) picks+=("edit-secrets") ;;
        9) picks+=("uninstall") ;;
        10) break ;;
        *) echo "Invalid." ;;
      esac
    done
    mapfile -t picks < <(printf "%s\n" "${picks[@]}" | awk '!seen[$0]++')
    [[ ${#picks[@]} -eq 0 ]] && { warn "No selection made; exiting."; exit 1; }
  fi
  REQUESTED_MODULES=("${picks[@]}")
}

# If --all set, expand
if [[ $ALL_FLAG -eq 1 ]]; then
  REQUESTED_MODULES=(base neovim zsh starship scripts)
fi
# If nothing specified, go interactive
if [[ ${#REQUESTED_MODULES[@]} -eq 0 ]]; then
  read -r -p "Install all modules (base, neovim, zsh, starship, scripts)? (Y/n): " ans
  if [[ ! "${ans:-Y}" =~ ^[nN]$ ]]; then
    REQUESTED_MODULES=(base neovim zsh starship scripts)
  else
    interactive_menu
  fi
fi

# ---------- Prompt: link vs copy (if not explicitly provided) ----------
mode_prompt_if_needed() {
  # Skip if user explicitly provided --mode or it's a dry run
  if [[ "${MODE}" == "${DEFAULT_MODE}" && "${DRY}" -eq 0 ]]; then
    echo
    echo "How should we set up your dotfiles?"
    echo
    echo "  [s] Symbolic links (shortcuts)  -> edit in repo, changes apply instantly (recommended)."
    echo "  [c] Copy files                  -> independent copies; safer if you might delete/move the repo."
    echo
    read -r -p "Use symbolic links or copies? (s/c) [default: s]: " ans
    case "$ans" in
      [cC]*) MODE="copy" ;;
      *) MODE="link" ;;
    esac
    echo
  fi
}

# ---------- Basic helpers (used even without modules) ----------
ensure_core_dirs() {
  for d in "${HOME}/.local/bin" "${HOME}/.local/share" "${HOME}/.config" "${HOME}/Apps" "${HOME}/.bin"; do
    [[ -d "$d" ]] || do_run mkdir -p "$d"
  done
}

# Safe deploy: SRC -> DEST with backup
deploy() {
  local src="$1" dest="$2"
  local parent; parent="$(dirname "$dest")"
  [[ -d "$parent" ]] || do_run mkdir -p "$parent"
  if [[ -L "$src" ]]; then
    local link_target
    link_target="$(readlink "$src")"
    local abs_link
    if [[ "$link_target" == /* ]]; then
      abs_link="$link_target"
    else
      abs_link="$(cd "$(dirname "$src")" && resolve_path "$link_target")"
    fi
    local abs_dest
    abs_dest="$(resolve_path "$dest")"
    if [[ -n "$abs_link" && -n "$abs_dest" && "$abs_link" == "$abs_dest" ]]; then
      warn "Skipping deploy of $src to $dest because source symlink resolves to destination (would create loop)."
      return
    fi
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    do_run mv -f "$dest" "${dest}.bak.$(date +%s)"
  fi
  if [[ "${MODE}" == "copy" ]]; then
    do_run cp -r "$src" "$dest"
  else
    do_run ln -s "$src" "$dest"
  fi
}

deploy_set() {
  local spec
  for spec in "$@"; do
    local left="${spec%%:*}" right="${spec#*:}"
    deploy "${REPO_ROOT}/${left}" "${right}"
  done
}

# Sanitize explicit hardcoded user paths in known files
sanitize_user_paths() {
  local targets=(
    ".config/hypr/hyprland.conf"
  )
  for rel in "${targets[@]}"; do
    local f="${REPO_ROOT}/${rel}"
    [[ -f "$f" ]] || continue
    if grep -q '/home/dusts' "$f"; then
      say "Sanitizing user path in: ${f}"
      do_run sed -i "s#/home/dusts#${HOME}#g" "$f"
    fi
  done
}

# Auto-discover & offer to deploy hidden dotfiles/dirs at repo root
deploy_hidden_dot_things() {
  say "Scanning for hidden files/dirs at repo root…"
  shopt -s dotglob nullglob
  local items_to_deploy=()
  
  # Find all hidden items at the root
  for p in "${REPO_ROOT}"/.*; do
    local base; base="$(basename "$p")"
    # Skip git internals, this installer, and the special-cased .config
    [[ "$base" =~ ^(\.|..|.git|.github|.gitignore|.gitmodules|.config)$ ]] && continue
    if [[ -f "$p" || -d "$p" ]]; then
      items_to_deploy+=("$base")
    fi
  done

  # Handle .config separately for a "merge" strategy
  if [[ -d "${REPO_ROOT}/.config" ]]; then
    say "Found .config directory, will merge its contents."
    for p in "${REPO_ROOT}"/.config/*; do
      local base; base="$(basename "$p")"
      [[ "$base" == "starship.toml" ]] && continue
      [[ "$base" == "starship" ]] && continue
      items_to_deploy+=(".config/${base}")
    done
  fi
  
  [[ ${#items_to_deploy[@]} -eq 0 ]] && { say "No hidden items found to deploy."; return; }

  echo
  echo "Found these items to deploy into your HOME directory:"
  printf '  - ~/%s\n' "${items_to_deploy[@]}"
  read -r -p "Deploy all of the above? (Y/n): " ans
  if [[ ! "${ans:-Y}" =~ ^[nN]$ ]]; then
    local specs=()
    for item in "${items_to_deploy[@]}"; do
      specs+=("${item}:${HOME}/${item}")
    done
    deploy_set "${specs[@]}"
  fi
}

# ---------- Source common.sh if present (pkg detection, etc.) ----------
if [[ -f "${MODULES_DIR}/common.sh" ]]; then
  # shellcheck disable=SC1090
  source "${MODULES_DIR}/common.sh"
else
  # Minimal fallbacks if modules/common.sh is missing
  have_pkg() { command -v "$1" >/dev/null 2>&1; }
  PKM=""
  detect_platform() {
    if [[ "$OSTYPE" == darwin* ]]; then PKM="brew"; return; fi
    if [[ -f /etc/os-release ]]; then . /etc/os-release; fi
    for c in apt dnf pacman zypper apk; do command -v "$c" >/dev/null 2>&1 && PKM="$c" && break; done
    [[ -z "$PKM" ]] && warn "No known package manager detected."
  }
  pkg_install() {
    [[ $# -eq 0 ]] && return 0
    case "$PKM" in
      apt) sudo apt-get update && sudo apt-get install -y "$@" ;;
      dnf) sudo dnf install -y "$@" ;;
      pacman) sudo pacman -Sy --needed --noconfirm "$@" ;;
      zypper) sudo zypper install -y "$@" ;;
      apk) sudo apk add --no-cache "$@" ;;
      brew) brew install "$@" ;;
      *) warn "Skipping package install: $* (unknown PKM)";;
    esac
  }
fi

# ---------- Module runner ----------
run_module() {
  local m="$1"
  if [[ -f "${MODULES_DIR}/${m}.sh" ]]; then
    banner "MODULE: ${m}"
    # shellcheck disable=SC1090
    source "${MODULES_DIR}/${m}.sh"
  else
    # Built-in minimal behaviors if module file missing
    banner "MODULE: ${m} (builtin minimal)"
    case "$m" in
      scripts)
        [[ -d "${REPO_ROOT}/Scripts" ]] && {
          do_run mkdir -p "${HOME}/Scripts"
          do_run rsync -a "${REPO_ROOT}/Scripts/" "${HOME}/Scripts/"
          say "Copied ./Scripts to ~/Scripts"
        }
        ;;
      zsh)
        pkg_install zsh || true
        deploy_set ".zshrc:${HOME}/.zshrc"
        ;;
      starship)
        if ! have starship; then
          say "Installing starship (attempt)…"
          if have brew; then brew install starship
          elif [[ "$PKM" == "apt" ]]; then curl -fsSL https://starship.rs/install.sh | sh -s -- -y
          else curl -fsSL https://starship.rs/install.sh | sh -s -- -y
          fi
        fi
        [[ -f "${REPO_ROOT}/.config/starship.toml" ]] && deploy_set ".config/starship.toml:${HOME}/.config/starship.toml"
        ;;
      neovim)
        # Simple tarball install stable
        local NVIM_DIR="${HOME}/Apps" BIN_DIR="${HOME}/.bin"
        do_run mkdir -p "${NVIM_DIR}" "${BIN_DIR}"
        local url
        if [[ "${NVIM_CHANNEL}" == "nightly" ]]; then
          url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
        else
          url="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | \
                 sed -n 's/.*"browser_download_url": *"\(.*nvim-linux-x86_64.tar.gz\)".*/\1/p' | head -n1)"
        fi
        [[ -z "$url" ]] && die "Could not determine Neovim download URL."
        TMP="$(mktemp -d)"
        do_run curl -fL "$url" -o "${TMP}/nvim.tar.gz"
        do_run tar -xzf "${TMP}/nvim.tar.gz" -C "${TMP}"
        do_run rm -rf "${NVIM_DIR}/nvim"
        do_run mv "${TMP}/nvim-linux-x86_64" "${NVIM_DIR}/nvim"
        [[ -e "${BIN_DIR}/nvim" ]] || do_run ln -s "${NVIM_DIR}/nvim/bin/nvim" "${BIN_DIR}/nvim"
        [[ -d "${REPO_ROOT}/.config/nvim" ]] && deploy_set ".config/nvim:${HOME}/.config/nvim"
        ;;
      base)
        detect_platform || true
        say "Ensuring core dirs (~/Apps, ~/.bin, ~/.local/*, ~/.config)…"
        ensure_core_dirs
        # Small sensible set; your module can do a richer set.
        pkg_install git curl unzip jq fzf ripgrep || true
        ;;
      *) warn "Unknown module '$m' and no module file found."; ;;
    esac
  fi
}

# ---------- Main ----------
say "Starting dotfiles installer"
ensure_core_dirs
sanitize_user_paths
mode_prompt_if_needed

# Export for modules
export REPO_ROOT MODE DRY NVIM_CHANNEL

# Run requested modules
for m in "${REQUESTED_MODULES[@]}"; do
  run_module "$m"
done

# After modules: offer to deploy hidden root dotfiles/dirs
deploy_hidden_dot_things

say "All done."
