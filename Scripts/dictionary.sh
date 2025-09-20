#!/bin/bash

# Absolute path to script.py
SCRIPT_PATH=~/Scripts/script.py

# Run sdcv with a word as an argument, capture output
sdcv_output=$(sdcv "$1")

# Pass the output to Python script using the full path
python3 "$SCRIPT_PATH" <<< "$sdcv_output"
