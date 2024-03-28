#!/bin/bash

# Move .config and .fonts to ~
# if they don't exist, create them
# if they do, only copy and don't
# overwrite
dotfile_items=(.bin .config .fonts .tmux .tmux.conf .zshrc)

function install_dir {
    for item in "${dotfile_items[@]}"; do
        # Check if item exists and is a directory
        if [[ -d "$item" ]]; then
            # Check if directory exists in ~
            if [[ -d "$HOME/$item" ]]; then
                # Prompt user to choose whether to overwrite or update
                echo "Directory $HOME/$item already exists."
                echo "Do you want to overwrite its contents or update it using rsync? [o/r/N]"
                read -r ANSWER
                if [[ "$ANSWER" == "o" ]]; then
                    rm -rf "$HOME/$item"  # Remove the existing directory and its contents
                elif [[ "$ANSWER" == "r" ]]; then
                    # Update the directory using rsync
                    rsync -ru --append --partial "$item"/ "$HOME/$item/"
                    continue  # Skip to the next item
                fi
            fi
            # If directory doesn't exist or user chooses to overwrite, create it and copy contents
            mkdir -p "$HOME/$item"
            cp -r "$item"/* "$HOME/$item/"
        else
            # If item is a file and exists in ~, ask whether to overwrite
            if [[ -e "$HOME/$item" ]]; then
                echo "Overwrite $item? [y/N]"
                read -r ANSWER
                if [[ "$ANSWER" != "y" ]]; then
                    continue
                else
                    cp "$item" "$HOME/$item"
                fi
            else
                # If item is a file and doesn't exist in ~, copy it
                cp "$item" "$HOME/$item"
            fi
        fi
    done
}

# Execute the function
install_dir
