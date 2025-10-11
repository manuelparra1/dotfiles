#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
# Module: zsh + configs + quality-of-life bits
# Expects common helpers from install_dotfiles:
#   say, warn, die, do_run, deploy_set, deploy, pkg_install, have
set -euo pipefail

banner "Zsh + config"

# --- local helpers (module-scoped, safe if common.sh not present) ---
ensure_line() {
  # ensure a single line exists in a file (exact text match)
  # usage: ensure_line FILE "literal line"
  local file="$1" line="$2"
  [[ -f "$file" ]] || do_run touch "$file"
  if ! grep -Fxq "$line" "$file"; then
    do_run bash -c 'printf "%s\n" "$0" >> "$1"' "$line" "$file"
  fi
}

append_block_once() {
  # append a small heredoc if a marker is not present
  # usage: append_block_once FILE "MARKER" <<'EOF' ... EOF
  local file="$1" marker="$2"
  shift 2
  if ! grep -Fq "$marker" "$file" 2>/dev/null; then
    do_run bash -c 'cat >> "$0"' "$file"
  fi
}

# --- install zsh if needed ---
if ! have zsh; then
  say "Installing zsh"
  pkg_install zsh || warn "Could not install zsh (continuing)"
fi

# --- set default shell to zsh (non-interactive safe) ---
if [[ "${SHELL:-}" != *"/zsh" ]] && have chsh; then
  say "Setting default shell to zsh (you may need to re-login)"
  do_run chsh -s "$(command -v zsh)" "${USER}"
fi

# --- ensure core dirs (PATH helpers, completions) ---
do_run mkdir -p "${HOME}/.local/bin" "${HOME}/.config" "${HOME}/.config/zsh" "${HOME}/.zfunc"

# --- deploy your repo zsh files ---
# .zshrc at repo root?
if [[ -f "${REPO_ROOT}/.zshrc" ]]; then
  deploy_set ".zshrc:${HOME}/.zshrc"
fi

# repo-level zsh config dir?
if [[ -d "${REPO_ROOT}/.config/zsh" ]]; then
  deploy_set ".config/zsh:${HOME}/.config/zsh"
fi

# popular extras if present
for f in ".p10k.zsh" ".zprofile" ".zlogin" ".zlogout" ".zshenv"; do
  [[ -f "${REPO_ROOT}/${f}" ]] && deploy_set "${f}:${HOME}/${f}"
done

# --- make sure ~/.local/bin is on PATH (early) ---
ensure_line "${HOME}/.zshrc" 'export PATH="$HOME/.local/bin:$PATH"'

# --- completions: add ~/.zfunc to fpath + compinit (once) ---
append_block_once "${HOME}/.zshrc" "# DOTFILES-ZFUNC-BEGIN" <<'EOF'
# DOTFILES-ZFUNC-BEGIN
# Add per-user function/completions directory
fpath=("$HOME/.zfunc" $fpath)
autoload -Uz compinit && compinit -u
# DOTFILES-ZFUNC-END
EOF

# --- optional: fzf key-bindings if installed system-wide ---
if have fzf; then
  if [[ -r "/usr/share/fzf/key-bindings.zsh" || -r "/usr/share/doc/fzf/examples/key-bindings.zsh" ]]; then
    append_block_once "${HOME}/.zshrc" "# DOTFILES-FZF-BEGIN" <<'EOF'
# DOTFILES-FZF-BEGIN
# fzf key-bindings if available
for f in /usr/share/fzf/key-bindings.zsh /usr/share/doc/fzf/examples/key-bindings.zsh; do
  [[ -r "$f" ]] && source "$f"
done
# DOTFILES-FZF-END
EOF
  fi
fi

say "Zsh configured."
