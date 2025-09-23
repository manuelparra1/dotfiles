#!/usr/bin/env bash

# Get today's date to highlight
TODAY=$(date +%Y-%m-%d)

# Get the current month's calendar
cal=$(calcurse --calendar --onemonth --no-legend --no-color --title "" | sed "s/$TODAY/$(echo -e '\\033[7m')$(date +%d)$(echo -e '\\033[0m')/")

# Replace newlines with <br> for HTML formatting
cal_html=$(echo "$cal" | sed ':a;N;$!ba;s/\n/<br>/')

echo "<span font='monospace'>$cal_html</span>"
