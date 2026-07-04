#!/bin/env bash

# Check if dhcpcd is enabled and stop it
sudo sv status dhcpcd
sudo rm -f /var/service/dhcpcd
# Check if wpa_supplicant is enabled and stop it
sudo sv status wpa_supplicant
sudo rm -f /var/service/wpa_supplicant
