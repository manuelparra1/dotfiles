#!/bin/bash

# Move .config and .fonts to ~
# if they don't exist, create them
# if they do, only copy and don't
# overwrite
function install_config {
    if [[ ! -d ~/.config ]]; then
        mkdir -p ~/.config
        cp -r .config/* ~/.config
    else
        # if .config contents exist in
        # ~/.config contents, ask whether to overwrite
        for file in ./.config/*; do
            filename=$(basename "$file")
            if [[ -e ~/.config/$filename ]]; then
                echo "Overwrite $filename? [y/N]"
                read -r ANSWER
                if [[ "$ANSWER" == "y" ]]; then
                    cp -r "$file" ~/.config
                fi
            else
                cp -r "$file" ~/.config/
            fi
        done
    fi
}

# Move .fonts to ~
# if it doesn't exist, create it
# if it does, only copy and don't
# overwrite
function install_fonts {
    if [[ ! -d ~/.fonts ]]; then
        mkdir -p ~/.fonts
        cp -r .fonts/* ~/.fonts
    else
        # if .fonts contents exist in
        # ~/.fonts contents, ask whether to overwrite
        for file in ./.fonts/*; do
            filename=$(basename "$file")
            if [[ -e ~/.fonts/$filename ]]; then
                echo "Overwrite $filename? [y/N]"
                read -r ANSWER
                if [[ "$ANSWER" == "y" ]]; then
                    cp -r "$file" ~/.fonts
                fi
            else
                cp -r "$file" ~/.fonts
            fi
        done
    fi
}

echo "Installing config"
echo "Are you sure? [y/N]"
read -r ANSWER
if [[ "$ANSWER" != "y" ]]
then
    echo "Ok, bye"
    exit 0
else
    install_config

echo "Installing fonts"
echo "Are you sure? [y/N]"
read -r ANSWER
if [[ "$ANSWER" != "y" ]]
then
    echo "Ok, bye"
    exit 0
else
    install_fonts
fi
fi
