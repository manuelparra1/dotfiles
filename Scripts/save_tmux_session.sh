#!/usr/bin/env bash

# 1. Trigger the tmux-resurrect save script 
# (This path matches your TPM setup)
~/.tmux/plugins/tmux-resurrect/scripts/save.sh

# 2. Brief pause to let the write-to-disk finish
sleep 0.5

# 3. Visual confirmation in the status bar
tmux display-message "Session Saved! Detaching..."

# NOTE: Detaching is done by the keybinding in ~/.tmux.conf
#
# 3. Optional: Detach after saving
# Uncomment the line below if you want it to always close the window too
# tmux detach-client
