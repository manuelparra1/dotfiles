#!/usr/bin/env bash
# add_new_created_key_ssh_agent.sh

# Only start agent if one isn't already provided by the environment
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "Starting SSH agent..."
    eval "$(ssh-agent -s)"
else
    echo "SSH agent already running."
fi

# Use $HOME instead of ~ for better script reliability
KEY_PATH="${1:-$HOME/.ssh/id_ed25519}"

# Check if the key is already added to avoid re-typing password
if ssh-add -l | grep -q "$(ssh-keygen -lf "$KEY_PATH" | awk '{print $2}')"; then
    echo "Key '$KEY_PATH' is already loaded."
else
    echo "Adding key: $KEY_PATH"
    ssh-add "$KEY_PATH"
fi
