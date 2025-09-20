#!/bin/bash

# Start a tmux session in alacritty
alacritty --class cmatrix -e tmux new-session \; \
    send-keys 'cmatrix' C-m
