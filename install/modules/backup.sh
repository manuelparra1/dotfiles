#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
# requires common.sh sourced by parent

banner "Create Full Backup of Existing Dotfiles"

# --- List of items to back up ---
# These are paths relative to the HOME directory.
# The script will only back them up if they exist.
declare -a POTENTIAL_PATHS=(
  ".config"
  ".zshrc"
  ".tmux.conf"
  ".p10k.zsh"
  ".zprofile"
  ".zshenv"
  "Scripts"
  "Apps/nvim"
  ".local/bin/nvim"
)

# --- Find which items actually exist ---
declare -a ACTUAL_PATHS=()
say "Scanning for existing files and directories to back up..."
for p in "${POTENTIAL_PATHS[@]}"; do
  if [[ -e "${HOME}/${p}" ]]; then
    ACTUAL_PATHS+=("$p")
  fi
done

if [[ ${#ACTUAL_PATHS[@]} -eq 0 ]]; then
  say "No existing dotfiles found to back up. Nothing to do."
  exit 0
fi

# --- Confirm with user ---
echo
say "The following items will be archived:"
for p in "${ACTUAL_PATHS[@]}"; do
  printf "  - ~/%s\n" "$p"
done
echo

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_FILE="${HOME}/dotfiles_backup_${TIMESTAMP}.tar.gz"

read -r -p "Create a backup archive at '${BACKUP_FILE}'? (Y/n): " ans
if [[ ! "${ans:-Y}" =~ ^[yY]$ ]]; then
  say "Backup cancelled."
  exit 0
fi

# --- Create the tarball ---
# We use -C to change to the HOME directory, so the paths in the archive
# are relative (e.g., '.config', not 'home/user/.config'). This makes
# restoration much cleaner.
say "Creating backup..."
if do_run "tar -czf '${BACKUP_FILE}' -C '${HOME}' -- ${ACTUAL_PATHS[*]}"; then
  say "Backup created successfully: ${BACKUP_FILE}"
else
  die "Backup failed. Please check permissions and available disk space."
fi

say "Backup module complete."
