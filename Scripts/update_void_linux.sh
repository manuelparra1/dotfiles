#!/bin/bash

# Update Void Linux system
echo "Syncing repositories and updating packages..."
sudo xbps-install -Su

# Check if xbps itself was updated and run again if needed
if xbps-install -un | grep -q "^xbps"; then
    echo "XBPS was updated, running update again..."
    sudo xbps-install -Su
fi

# Remove orphaned packages
echo "Removing orphaned packages..."
sudo xbps-remove -o

# Clean package cache
echo "Cleaning package cache..."
sudo xbps-remove -O

# Check for processes using old libraries (requires xtools)
if command -v xcheckrestart &> /dev/null; then
    echo "Checking for services requiring restart..."
    xcheckrestart
fi

echo "Update complete!"
