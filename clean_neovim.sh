#!/bin/bash
# clean_neovim.sh
# Remove Neovim configuration dotfiles

echo "Cleaning Neovim configuration..."
echo "Are you sure? [y/N]"
read -r ANSWER

if [[ "$ANSWER" != "y" ]]
then
    echo "Ok, bye"
    exit 0
else
    rm -rf ~/.config/nvim
    rm -rf ~/.local/share/nvim
    rm -rf ~/.local/state/nvim
    rm -rf ~/.cache/nvim
fi

echo "Done"
