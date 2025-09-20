#!/bin/bash
# ============================================
# installer.sh
# Author: @manuelparra1
# Date: 2024-09-08 
# Version: 1.0
# Description: Installs codeium vim version plugin in neovim
# # Usage: ./install_codeium.sh
# ============================================

# Install codeium
git clone https://github.com/Exafunction/codeium.vim ~/.config/nvim/pack/Exafunction/start/codeium.vim

# init.lua packadd codeium
echo "-- Manual Installation Codeium" > ~/.config/nvim/init.lua
echo "vim.o.packpath = vim.o.packpath .. ',~/.config/nvim'" >> ~/.config/nvim/init.lua
echo "vim.cmd([[packadd codeium.vim]])" >> ~/.config/nvim/init.lua
echo "Don't forget to change keybinding with nvim-cmp"
sleep 1
echo "Dotfiles Installed Successfully"
