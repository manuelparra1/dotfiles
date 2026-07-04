#!/usr/bin/env bash

env_dir=~/Environments/scraping
venv_path="$env_dir"/venv

# Check if environment directory already exists
if [ -d "$env_dir" ]; then
    echo "Environment directory already exists at $env_dir"
    exit 1
fi

# Check if virtual environment already exists
if [ -d "$venv_path" ]; then
    echo "Virtual environment already exists at $venv_path"
    exit 1
fi

mkdir -p "$env_dir"
uv venv --symlink --python 3.11 "$env_dir"
