#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
: "${REPO_ROOT:=${DOTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")"/../../.. && pwd)}}"
: "${DOTS_ROOT:=${REPO_ROOT}}"
export REPO_ROOT DOTS_ROOT

# Logging
say()   { printf "\033[1;36m==>\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
die()   { printf "\033[1;31m[err]\033[0m %s\n" "$*" >&2; exit 1; }
banner(){ printf "\n\033[1;35m==== %s ====\033[0m\n" "$*"; }

do_run() {
  if [[ "${DRY:-0}" -eq 1 ]]; then
    printf "[dry] %s\n" "$*"
    return 0
  fi

  if [[ $# -eq 1 ]]; then
    eval "$1"
  else
    "$@"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# Detect distro / package manager
PKM=""  # apt|dnf|pacman|zypper|apk|brew
OS_FAMILY="" # linux|darwin
detect_platform() {
  if [[ "$OSTYPE" == darwin* ]]; then
    OS_FAMILY=darwin
    PKM=brew
    return
  fi

  OS_FAMILY=linux
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "${ID_LIKE:-$ID}" in
      *debian*|debian|ubuntu|linuxmint) PKM=apt ;;
      *fedora*|fedora|rhel|centos)      PKM=dnf ;;
      *arch*|arch)                      PKM=pacman ;;
      *suse*|sles|opensuse*)            PKM=zypper ;;
      *alpine*)                         PKM=apk ;;
      *) PKM="" ;;
    esac
  fi
  [[ -z "$PKM" ]] && for c in apt dnf pacman zypper apk; do have "$c" && PKM="$c" && break; done
  [[ -z "$PKM" ]] && die "Could not detect a supported package manager."
}

print_platform() {
  say "OS: ${OS_FAMILY}, PKM: ${PKM}"
}

# Package name mapping per manager
pkg_name() {
  # $1 generic name -> outputs manager-specific name
  local name="$1"
  case "$PKM" in
    apt)
      case "$name" in
        bat) echo "bat" ;;        # newer debians have bat (older: batcat)
        fd)  echo "fd-find" ;;
        ripgrep) echo "ripgrep" ;;
        fzf) echo "fzf" ;;
        zsh) echo "zsh" ;;
        git) echo "git" ;;
        curl) echo "curl" ;;
        unzip) echo "unzip" ;;
        make) echo "build-essential" ;; # for dev tools
        uv) echo "" ;; # curl installer used
        node) echo "" ;; # nvm used
        python3) echo "python3" ;;
        pipx) echo "pipx" ;;
        jq) echo "jq" ;;
        stow) echo "stow" ;;
        *) echo "$name" ;;
      esac
      ;;
    dnf)
      case "$name" in
        fd) echo "fd-find" ;; bat) echo "bat" ;;
        make) echo "make automake gcc gcc-c++ kernel-devel" ;;
        *) echo "$name" ;;
      esac
      ;;
    pacman)
      case "$name" in
        fd) echo "fd" ;;
        pipx) echo "python-pipx" ;;
        make) echo "base-devel" ;;
        node) echo "nodejs npm" ;; # Arch often fine w/ system node
        *) echo "$name" ;;
      esac
      ;;
    zypper|apk|brew) echo "$name" ;;
    *) echo "$name" ;;
  esac
}

ensure_core_dirs() {
  for d in "${HOME}/.local/bin" "${HOME}/.local/share" "${HOME}/.config"; do
    [[ -d "$d" ]] || do_run mkdir -p "$d"
  done
}

pkg_install() {
  # install many generic names, auto-translated
  local translated=()
  for n in "$@"; do
    local p; p="$(pkg_name "$n")"
    [[ -n "$p" ]] && translated+=("$p")
  done
  [[ ${#translated[@]} -eq 0 ]] && return 0

  case "$PKM" in
    apt)   do_run sudo apt-get update && do_run sudo apt-get install -y "${translated[@]}" ;;
    dnf)   do_run sudo dnf install -y "${translated[@]}" ;;
    pacman) do_run sudo pacman -Sy --needed --noconfirm "${translated[@]}" ;;
    zypper) do_run sudo zypper install -y "${translated[@]}" ;;
    apk)   do_run sudo apk add --no-cache "${translated[@]}" ;;
    brew)  do_run brew install "${translated[@]}" ;;
    *) die "Unsupported PKM: $PKM" ;;
  esac
}

# Link/copy helper with backup
deploy() {
  # deploy SRC -> DEST (file or dir)
  local src="$1" dest="$2"
  local parent; parent="$(dirname "$dest")"
  [[ -d "$parent" ]] || do_run mkdir -p "$parent"

  # --- safety check for symlink loops ---
  # If a parent of the destination is already a link, this file is likely covered.
  local check_parent="$parent"
  while [[ "$check_parent" != "/" && "$check_parent" != "." && -n "$check_parent" ]]; do
    if [[ -L "$check_parent" ]]; then
      warn "Parent '$check_parent' is a symlink; skipping deploy for '$dest' to avoid loops."
      return 0
    fi
    check_parent="$(dirname "$check_parent")"
  done
  # --- end safety check ---

  if [[ -e "$dest" || -L "$dest" ]]; then
    do_run mv -f "$dest" "${dest}.bak.$(date +%s)"
  fi

  if [[ "${MODE}" == "copy" ]]; then
    do_run cp -r "$src" "$dest"
  else
    do_run ln -s "$src" "$dest"
  fi
}

# Bulk deploy convenience (relative to $DOTS_ROOT)
deploy_set() {
  # args are "repo_rel_path:abs_destination"
  local spec
  for spec in "$@"; do
    local left="${spec%%:*}" right="${spec#*:}"
    deploy "${DOTS_ROOT}/${left}" "${right}"
  done
}
