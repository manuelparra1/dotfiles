#!/usr/bin/env bash
set -euo pipefail

# Defaults
CHANNEL="${CHANNEL:-nightly}"    # nightly|stable|vX.Y.Z (e.g., v0.11.4)
PREFIX="${PREFIX:-$HOME/Apps/nvim}"
BIN_DIR="${BIN_DIR:-$HOME/.bin}"
TARBALL="nvim-linux-x86_64.tar.gz"
REPO="neovim/neovim"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--nightly | --stable | --version vX.Y.Z] [--prefix DIR] [--bindir DIR]

Options:
  --nightly            Install latest nightly (default)
  --stable             Install latest stable (via GitHub Releases API)
  --version vX.Y.Z     Install specific tagged version (e.g. v0.11.4)
  --prefix DIR         Install under DIR (default: $PREFIX)
  --bindir DIR         Create 'nvim' shim/symlink in DIR (default: $BIN_DIR)
  -h, --help           Show this help

Examples:
  CHANNEL=nightly PREFIX=~/Apps BIN_DIR=~/.bin $(basename "$0")
  $(basename "$0") --stable
  $(basename "$0") --version v0.11.4
EOF
}

# --- parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --nightly) CHANNEL="nightly"; shift;;
    --stable)  CHANNEL="stable";  shift;;
    --version) CHANNEL="${2:?need a tag like v0.11.4}"; shift 2;;
    --prefix)  PREFIX="${2:?}"; shift 2;;
    --bindir)  BIN_DIR="${2:?}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage; exit 1;;
  esac
done

# --- preflight checks ---
have() { command -v "$1" >/dev/null 2>&1; }

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[error] This installer supports Linux only." >&2
  exit 1
fi

arch="$(uname -m)"
if [[ "$arch" != "x86_64" && "$arch" != "amd64" ]]; then
  echo "[error] This tarball is for x86_64 only. Your arch: $arch" >&2
  exit 1
fi

for req in curl tar; do
  have "$req" || { echo "[error] Missing dependency: $req" >&2; exit 1; }
done

# glibc sanity note (Neovim 0.10+ often needs glibc >= 2.28/2.29 on some distros)
glibc_ver=""
if have ldd; then
  # first numeric token on first line typically is glibc version
  glibc_ver="$(ldd --version 2>/dev/null | head -n1 | grep -Eo '[0-9]+\.[0-9]+' || true)"
  echo "[info] Detected glibc: ${glibc_ver:-unknown}"
  # Soft warn only; exact floor can vary by build. See release notes/issues.
fi

# --- figure out which URL/tag to use ---
api_base="https://api.github.com/repos/${REPO}"

resolve_channel() {
  case "$CHANNEL" in
    nightly)
      TAG="nightly"
      URL="https://github.com/${REPO}/releases/download/nightly/${TARBALL}"
      ;;
    stable)
      # Use GitHub Releases API "latest"
      json="$(curl -fsSL "$api_base/releases/latest")"
      TAG="$(printf '%s' "$json" | grep -Eo '"tag_name":\s*"v[0-9]+\.[0-9]+\.[0-9]+"' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')"
      if [[ -z "${TAG:-}" ]]; then
        echo "[error] Could not determine latest stable tag via API." >&2
        exit 1
      fi
      URL="https://github.com/${REPO}/releases/download/${TAG}/${TARBALL}"
      ;;
    v[0-9]*)
      TAG="$CHANNEL"
      URL="https://github.com/${REPO}/releases/download/${TAG}/${TARBALL}"
      ;;
    *)
      echo "[error] Unknown CHANNEL: $CHANNEL" >&2
      exit 1
      ;;
  esac
}

resolve_channel
echo "[info] Channel: $CHANNEL  Tag: $TAG"
echo "[info] Download URL: $URL"

# --- install layout ---
mkdir -p "$PREFIX" "$BIN_DIR"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# --- fetch & verify existence ---
echo "[info] Downloading tarball..."
curl -fL --retry 3 -o "$workdir/$TARBALL" "$URL"

# --- extract ---
echo "[info] Extracting..."
tar -C "$workdir" -xzf "$workdir/$TARBALL"

# Tarball unpacks to ./nvim-linux-x86_64
src_dir="$workdir/nvim-linux-x86_64"
[[ -x "$src_dir/bin/nvim" ]] || { echo "[error] nvim binary not found after extract." >&2; exit 1; }

# --- install to versioned dir ---
target="$PREFIX/$TAG"
if [[ -e "$target" ]]; then
  ts=$(date +%Y%m%d-%H%M%S)
  mv "$target" "${target}.bak-${ts}"
  echo "[warn] Existing $target was moved to ${target}.bak-${ts}"
fi
mkdir -p "$target"
cp -a "$src_dir/." "$target/"

# --- create shim/symlink ---
shim="$BIN_DIR/nvim"
if [[ -e "$shim" || -L "$shim" ]]; then
  rm -f "$shim"
fi
# Prefer a tiny wrapper for robustness across PATH/envs
cat > "$shim" <<EOF
#!/usr/bin/env bash
exec "$target/bin/nvim" "\$@"
EOF
chmod +x "$shim"

echo "[ok] Installed Neovim ($TAG) to: $target"
echo "[ok] Shim created at: $shim"
echo
echo "Add to PATH if needed (bash/zsh):"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
echo
echo "Run: nvim --version"
