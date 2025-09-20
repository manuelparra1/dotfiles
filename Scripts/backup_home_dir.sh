#!/bin/bash

# Define the backup directory (change as needed)
BACKUP_DIR="./hyprland_backup"
mkdir -p "$BACKUP_DIR"

# Backup .config: only *.toml files and specific subdirectories.
CONFIG_SRC="$HOME/.config"
CONFIG_DEST="$BACKUP_DIR/.config"

if [ -d "$CONFIG_SRC" ]; then
  mkdir -p "$CONFIG_DEST"

  echo "Backing up *.toml files from $CONFIG_SRC..."
  # Copy only *.toml files from the root of .config
  rsync -av --update --include='*.toml' --exclude='*' "$CONFIG_SRC/" "$CONFIG_DEST/"

  # List of .config subdirectories to backup
  declare -a config_dirs=("bat" "foot" "ghostty" "kitty" "nvim" "sway" "hypr" "Typora" "waybar" "wofi" "zsh")
  for dir in "${config_dirs[@]}"; do
    if [ -d "$CONFIG_SRC/$dir" ]; then
      echo "Backing up $dir..."
      mkdir -p "$CONFIG_DEST/$dir"
      rsync -av --update "$CONFIG_SRC/$dir/" "$CONFIG_DEST/$dir/"
    else
      echo "Directory $CONFIG_SRC/$dir not found, skipping."
    fi
  done
else
  echo "Directory $CONFIG_SRC does not exist. Skipping .config backup."
fi

# Backup additional configuration files (if they exist)
echo "Backing up additional configuration files..."
for file in "$HOME/.bliss_dircolors" "$HOME/.zshrc" "$HOME/.zsh_history" "$HOME/.tmux.conf"; do
  if [ -e "$file" ]; then
    rsync -av --update "$file" "$BACKUP_DIR/"
  else
    echo "File $file not found, skipping."
  fi
done

# Backup custom directories
echo "Backing up custom directories..."
declare -a custom_dirs=("$HOME/.bin" "$HOME/aston" "$HOME/Github" "$HOME/Apps" "$HOME/Projects" "$HOME/Scripts")
for dir in "${custom_dirs[@]}"; do
  if [ -d "$dir" ]; then
    if [ "$dir" == "$HOME/aston" ]; then
      echo "Backing up $dir (excluding directories starting with .stfolder or .stversion)..."
      rsync -av --update --exclude='.stfolder*' --exclude='.stversion' "$HOME/aston" "$BACKUP_DIR/"
    else
      echo "Backing up $dir..."
      rsync -av --update "$dir" "$BACKUP_DIR/"
    fi
  else
    echo "Custom directory $dir not found, skipping."
  fi
done

# Backup personal directories
echo "Backing up personal files..."
declare -a personal_dirs=("$HOME/Documents" "$HOME/Downloads" "$HOME/Desktop" "$HOME/Pictures" "$HOME/Videos" "$HOME/Music")
for dir in "${personal_dirs[@]}"; do
  if [ -d "$dir" ]; then
    rsync -av --update "$dir" "$BACKUP_DIR/"
  else
    echo "Personal directory $dir not found, skipping."
  fi
done

echo "Backup complete."
