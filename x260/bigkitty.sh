#!/usr/bin/env bash

kitty &
sleep 1
xdotool search --sync --onlyvisible --class kitty windowactivate --sync %@
xdotool key --clearmodifiers --delay 100ms F11
