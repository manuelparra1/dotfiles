#!/bin/bash

# Install Homebrew

if ! command -v brew &> /dev/null
then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed"
    echo "Do you want to update it? [y/N]"
    read -r ANSWER
    if [[ "$ANSWER" != "y" ]]; then
        echo "Ok, bye"
        exit 0
    else
        brew update
    fi
fi
