#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
# requires common.sh sourced by parent

banner "Edit Encrypted Secrets"

# --- Check for dependencies ---
have sops || die "sops is not installed. Please run the 'secrets' module first."
have age || die "age is not installed. Please run the 'secrets' module first."

# --- Check for age key ---
KEY_FILE="${HOME}/.config/sops/age/keys.txt"
if [[ ! -f "$KEY_FILE" ]]; then
  die "Age key not found at ${KEY_FILE}. Please run the 'secrets' module to set it up first."
fi

# --- Check for secrets file ---
SECRETS_FILE="${REPO_ROOT}/secrets.yaml"
if [[ ! -f "$SECRETS_FILE" ]]; then
  die "Encrypted secrets file not found at ${SECRETS_FILE}."
fi

# --- Open for editing ---
say "Opening secrets.yaml for editing in your default editor ($EDITOR)..."
say "When you save and close, the file will be automatically re-encrypted."

# The `sops` command will inherit the EDITOR variable from the current shell.
# We run it in a subshell to avoid any potential script-breaking behavior.
( do_run "sops '${SECRETS_FILE}'" )

if [[ $? -eq 0 ]]; then
  say "File saved and re-encrypted successfully."
else
  warn "Editor returned a non-zero exit code. Your changes may not have been saved."
fi

say "Edit Secrets module complete."
