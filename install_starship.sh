#!/bin/bash

# install_starship.sh
if ! command -v starship &> /dev/null
then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh
else
    echo "Starship already installed"
fi
