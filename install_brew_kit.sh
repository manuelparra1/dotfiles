#!/bin/bash

utility_list=(git nvim tmux node npm unzip fzf gnupg ripgrep fd)

# Check if list of utilities exists in system
function verify_list {
    local to_install=()

    for utility in "${utility_list[@]}"; do
        if ! command -v "$utility" &> /dev/null; then
            # keep utility in list
            to_install+=("$utility")
        fi
    done
    echo "${to_install[@]}"
}

# Install utilities using brew
function install_brew {
    local to_install=$(verify_list)
    if [[ ${#to_install[@]} -gt 0 ]]; then
        brew install "${to_install[@]}"
    else
        echo "All utilities are already installed."
    fi
}

# `brew install` starter kit
echo "\`brew\` installing starter kit for you"
echo "Are you sure? [y/N]"
read -r ANSWER
if [[ "$ANSWER" != "y" ]]; then
    echo "Ok, bye"
    exit 0
else
    install_brew
fi
