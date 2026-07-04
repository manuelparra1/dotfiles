#!/usr/bin/env bash

# ==============================================================================
# VOID LINUX AUTO-CONNECTOR FOR RK-84Pro5.0 (Single-Keyboard Safe)
# ==============================================================================
# TARGET MAC: ED:C5:7B:C3:37:1A
# ==============================================================================

# 1. Install Dependencies
echo ">>> [1/4] Checking dependencies..."
if ! command -v bluetoothctl >/dev/null; then
    sudo xbps-install -Sy bluez blueman
fi

# 2. Ensure Service is Running
echo ">>> [2/4] Waking up Bluetooth Daemon..."
if [ ! -L /var/service/bluetoothd ]; then
    sudo ln -s /etc/sv/bluetoothd /var/service/
    sleep 3
fi

# 3. Fix Permissions
if ! groups $USER | grep -q "bluetooth"; then
    echo ">>> [3/4] Adding $USER to bluetooth group..."
    sudo usermod -aG bluetooth $USER
fi

# 4. The Countdown (Crucial for Single Keyboard Setup)
echo "========================================================================"
echo ">>> [4/4] PREPARE FOR PAIRING"
echo "    You have 10 seconds to:"
echo "    1. Unplug this keyboard"
echo "    2. Turn the switch ON (Back of keyboard)"
echo "    3. Long Press Fn + Q until it flashes"
echo "========================================================================"

for i in 10 9 8 7 6 5 4 3 2 1; do
    printf "    Starting in $i...\r"
    sleep 1
done
echo "    LAUNCHING BLUETOOTH PAIRING NOW!                    "

# 5. Fire the Pairing Commands
bluetoothctl <<EOF
power on
scan on
# Trust first to enable auto-reconnect logic
trust ED:C5:7B:C3:37:1A
# Pair (Using 'Just Works' mode for 5.0)
pair ED:C5:7B:C3:37:1A
# Connect immediately
connect ED:C5:7B:C3:37:1A
quit
EOF

echo ">>> DONE. Setup complete."
