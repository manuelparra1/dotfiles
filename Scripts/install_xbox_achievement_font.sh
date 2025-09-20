#!/bin/bash

# Check if base-devel and git are installed
if ! pacman -Q base-devel git &>/dev/null; then
  echo "Installing base-devel and git..."
  sudo pacman -S --needed base-devel git
fi

# Check if yay is installed
if ! command -v yay &>/dev/null; then
  echo "Installing yay..."
  git clone https://aur.archlinux.org/yay.git
  cd yay || exit
  makepkg -si
  cd ..
fi

# Check if ttf-segoe-ui is installed
if ! pacman -Q ttf-segoe-ui &>/dev/null && ! yay -Q ttf-segoe-ui &>/dev/null; then
  echo "Installing ttf-segoe-ui font..."
  yay -S --noconfirm ttf-segoe-ui
  fc-cache -fv
else
  echo "ttf-segoe-ui is already installed."
fi
