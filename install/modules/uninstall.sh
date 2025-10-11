#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
# requires common.sh sourced by parent

banner "Dotfiles Uninstaller"

# --- Offer to restore from full backup first ---
shopt -s nullglob
BACKUP_FILES=("$HOME"/dotfiles_backup_*.tar.gz)
shopt -u nullglob

if [[ ${#BACKUP_FILES[@]} -gt 0 ]]; then
  echo
  warn "Found one or more full backup archives. Restoring from a backup is the recommended way to revert."
  printf "  - %s\n" "${BACKUP_FILES[@]}"
  read -r -p "Do you want to restore from a full backup now? (y/N): " ans
  if [[ "$ans" =~ ^[yY]$ ]]; then
    # For simplicity, we'll use the latest backup. A more complex script could offer a choice.
    LATEST_BACKUP="$(ls -t "$HOME"/dotfiles_backup_*.tar.gz | head -n1)"
    
    warn "This will overwrite any files that conflict with the backup archive."
    read -r -p "Restore from '${LATEST_BACKUP}'? (y/N): " restore_ans
    if [[ "$restore_ans" =~ ^[yY]$ ]]; then
      say "First, removing all symlinks created by the installer..."
      # We still need to remove the links before restoring.
      # This logic is duplicated below, but it's necessary here.
      shopt -s dotglob nullglob
      MANAGED_DOTFILES=()
      for p in "${REPO_ROOT}"/.*; do
        local base; base="$(basename "$p")"
        [[ "$base" =~ ^(\.|..|.git|.github|.gitignore|.gitmodules)$ ]] && continue
        [[ -f "$p" || -d "$p" ]] && MANAGED_DOTFILES+=("$base")
      done
      shopt -u nullglob
      MANAGED_ITEMS=( ".config/nvim" ".config/starship.toml" "${MANAGED_DOTFILES[@]}" )
      for item in "${MANAGED_ITEMS[@]}"; do
        dest="${HOME}/${item}"
        if [[ -L "$dest" ]]; then
          link_target="$(readlink "$dest")"
          if [[ "$link_target" == "${REPO_ROOT}/${item}" ]]; then
            say "Removing symlink: ${dest}"
            do_run rm "$dest"
          fi
        fi
      done

      say "Restoring from backup..."
      if do_run "tar -xzf '${LATEST_BACKUP}' -C '${HOME}'"; then
        say "Restore complete."
        exit 0
      else
        die "Restore failed. Please check the backup file and permissions."
      fi
    fi
  fi
fi

say "Proceeding with standard uninstall..."

# --- Confirmation ---
echo
warn "This will remove symlinks and configurations managed by this dotfiles repo."
warn "It will offer to restore backups for replaced files."
warn "It will NOT uninstall packages (e.g., git, zsh, neovim packages)."
echo
read -r -p "Are you absolutely sure you want to continue? (y/N): " ans
if [[ ! "$ans" =~ ^[yY]$ ]]; then
  say "Uninstall cancelled."
  exit 0
fi

# --- List of managed items ---
# This list should correspond to what the installer deploys.
shopt -s dotglob nullglob
MANAGED_ITEMS=()

# Find hidden files/dirs at the repo root (excluding .config)
for p in "${REPO_ROOT}"/.*; do
  local base; base="$(basename "$p")"
  [[ "$base" =~ ^(\.|..|.git|.github|.gitignore|.gitmodules|.config)$ ]] && continue
  [[ -f "$p" || -d "$p" ]] && MANAGED_ITEMS+=("$base")
done

# Add items from inside the repo's .config directory
if [[ -d "${REPO_ROOT}/.config" ]]; then
  for p in "${REPO_ROOT}"/.config/*; do
    MANAGED_ITEMS+=(".config/$(basename "$p")")
  done
fi
shopt -u dotglob

# --- Remove symlinks and restore backups ---
say "Scanning for managed symlinks in ${HOME}..."
for item in "${MANAGED_ITEMS[@]}"; do
  dest="${HOME}/${item}"
  if [[ -L "$dest" ]]; then
    # Check if it points to our repo, to be safe
    link_target="$(readlink "$dest")"
    if [[ "$link_target" == "${REPO_ROOT}/${item}" ]]; then
      say "Removing symlink: ${dest}"
      do_run rm "$dest"

      # Restore backup if found
      shopt -s nullglob
      backups=("$dest".bak.*)
      shopt -u nullglob
      if [[ ${#backups[@]} -gt 0 ]]; then
        latest_backup="${backups[-1]}" # Get the most recent one
        read -r -p "  Found backup '${latest_backup}'. Restore it? (y/N): " restore_ans
        if [[ "$restore_ans" =~ ^[yY]$ ]]; then
          say "  Restoring backup to ${dest}"
          do_run mv "$latest_backup" "$dest"
        fi
      fi
    else
      warn "Skipping '${dest}' as it is a symlink but does not point to this repo."
    fi
  fi
done

# --- Remove copied/installed assets ---
say "Scanning for other managed assets..."

# Scripts directory
if [[ -d "${HOME}/Scripts" ]]; then
  read -r -p "Remove the '~/Scripts' directory? (y/N): " rmdir_ans
  if [[ "$rmdir_ans" =~ ^[yY]$ ]]; then
    say "Removing ~/Scripts..."
    do_run rm -rf "${HOME}/Scripts"
  fi
fi

# Neovim installation
if [[ -d "${HOME}/Apps/nvim" ]]; then
  read -r -p "Remove the Neovim installation from '~/Apps/nvim'? (y/N): " rmnvim_ans
  if [[ "$rmnvim_ans" =~ ^[yY]$ ]]; then
    say "Removing ~/Apps/nvim..."
    do_run rm -rf "${HOME}/Apps/nvim"
    # Also remove the shim
    if [[ -e "${HOME}/.local/bin/nvim" ]]; then
      do_run rm -f "${HOME}/.local/bin/nvim"
    fi
  fi
fi

# Decrypted secrets file
if [[ -f "${HOME}/.secrets.env" ]];
then
  say "Removing decrypted secrets file: ~/.secrets.env"
  do_run rm -f "${HOME}/.secrets.env"
fi


# --- Final Guidance ---
banner "Uninstall Complete"
say "The following actions were performed:"
echo "  - Removed symlinks pointing to this dotfiles repository."
echo "  - Offered to restore backups."
echo "  - Offered to remove ~/Scripts, ~/Apps/nvim, and ~/.secrets.env."
echo
say "What was NOT done:"
echo "  - Packages installed via apt, pacman, etc., have NOT been removed."
echo "    (e.g., zsh, curl, git, fzf, ripgrep, etc.)"
echo "  - Your default shell has NOT been changed. If it is zsh, you can change it back by running:"
echo "      chsh -s /bin/bash"
echo "  - The dotfiles repository itself at '${REPO_ROOT}' has not been touched."

say "Uninstall module complete."
