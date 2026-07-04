#!/usr/bin/env bash
# i3blocks battery block (sysfs-first, robust fallbacks)

set -u

# -------- Helpers --------
read_first_existing() {
  # usage: read_first_existing /path/a /path/b ...
  local f
  for f in "$@"; do
    [[ -r "$f" ]] && { cat "$f"; return 0; }
  done
  return 1
}

first_glob_dir() {
  # usage: first_glob_dir "/sys/class/power_supply/BAT*"
  local d
  for d in $1; do
    [[ -d "$d" ]] && { printf '%s\n' "$d"; return 0; }
  done
  return 1
}

uevent_get() {
  # usage: uevent_get /path/to/uevent KEY
  local uevent_file="$1" key="$2"
  [[ -r "$uevent_file" ]] || return 1
  awk -F= -v k="$key" '$1==k {print $2; exit}' "$uevent_file"
}

is_int() { [[ "${1-}" =~ ^[0-9]+$ ]]; }

# -------- Locate power supplies --------
BAT_PATH="$(first_glob_dir "/sys/class/power_supply/BAT*")" || BAT_PATH=""
AC_PATH="$(first_glob_dir "/sys/class/power_supply/AC*")"   || AC_PATH=""

# -------- Read AC online (best effort) --------
AC_ONLINE=""
if [[ -n "$AC_PATH" ]]; then
  AC_ONLINE="$(read_first_existing "$AC_PATH/online" || true)"
fi
is_int "$AC_ONLINE" || AC_ONLINE=""

# -------- Read battery present/status/percent --------
PRESENT="1"     # per kernel docs: if 'present' does not exist, consider present
STATE="Unknown"
PCT=""

if [[ -n "$BAT_PATH" ]]; then
  # present
  if [[ -r "$BAT_PATH/present" ]]; then
    PRESENT="$(<"$BAT_PATH/present")"
    is_int "$PRESENT" || PRESENT="1"
  fi

  # status
  [[ -r "$BAT_PATH/status" ]] && STATE="$(<"$BAT_PATH/status")"
  [[ -n "$STATE" ]] || STATE="Unknown"

  # capacity: prefer capacity file, then uevent, then compute from charge/energy
  if [[ -r "$BAT_PATH/capacity" ]]; then
    PCT="$(<"$BAT_PATH/capacity")"
  else
    PCT="$(uevent_get "$BAT_PATH/uevent" "POWER_SUPPLY_CAPACITY" || true)"
  fi

  if ! is_int "$PCT"; then
    # Compute if possible: charge_* or energy_*
    now="$(read_first_existing "$BAT_PATH/charge_now" "$BAT_PATH/energy_now" || true)"
    full="$(read_first_existing "$BAT_PATH/charge_full" "$BAT_PATH/energy_full" || true)"
    if is_int "$now" && is_int "$full" && [[ "$full" -gt 0 ]]; then
      PCT="$(awk -v n="$now" -v f="$full" 'BEGIN { printf("%d\n", (n*100)/f) }')"
    else
      PCT=""
    fi
  fi
fi

# -------- Icons / thresholds --------
icon_empty=""
icon_low=""
icon_mid=""
icon_high=""
icon_full=""
icon_charging=""

t_low=15
t_mid=35
t_high=65
t_full=90

# -------- Decide output for missing battery --------
if [[ "$PRESENT" == "0" ]] || [[ -z "$BAT_PATH" ]]; then
  # Battery absent: show AC-only if online=1, otherwise "No battery"
  if [[ "$AC_ONLINE" == "1" ]]; then
    TEXT="AC (no battery)"
  else
    TEXT="No battery"
  fi

  # i3blocks fields
  echo "$TEXT"
  [[ -n "${BLOCK_NAME-}" ]] && echo "$TEXT"
  exit 0
fi

# -------- Choose icon by percentage --------
ICON="$icon_empty"
if is_int "$PCT"; then
  if   [[ "$PCT" -le "$t_low"  ]]; then ICON="$icon_empty"
  elif [[ "$PCT" -le "$t_mid"  ]]; then ICON="$icon_low"
  elif [[ "$PCT" -le "$t_high" ]]; then ICON="$icon_mid"
  elif [[ "$PCT" -le "$t_full" ]]; then ICON="$icon_high"
  else                               ICON="$icon_full"
  fi
fi

# -------- Colors (optional) --------
COLOR=""
if is_int "$PCT" && [[ "$PCT" -le "$t_low" ]] && [[ "$STATE" == "Discharging" ]]; then
  COLOR="#ff5555"
elif [[ "$STATE" == "Charging" ]]; then
  COLOR="#8ec07c"
fi

# -------- Compose text --------
PCT_SHOW="${PCT:----}"   # shows '---' if empty/unset (note the 4 dashes)
if [[ "$STATE" == "Charging" ]]; then
  TEXT="$icon_charging $ICON ${PCT_SHOW}%"
else
  TEXT="${PCT_SHOW}% $ICON"
fi

# -------- Print for i3blocks --------
# Line 1 = full_text, line 2 = short_text (optional), line 3 = color (optional).
echo "$TEXT"
[[ -n "${BLOCK_NAME-}" ]] && echo "$TEXT"
[[ -n "$COLOR" ]] && echo "$COLOR"
