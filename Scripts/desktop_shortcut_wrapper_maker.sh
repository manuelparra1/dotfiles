#!/usr/bin/env bash

# make-wrappers.sh
# What it does:
# - Reads Name, Exec, Icon from the system .desktop.
# - Strips common field codes like %f (not needed for most cases).
# - Resolves Exec to a full path when possible.
# - Writes a -wrapper.desktop in your user applications dir without OnlyShowIn/Hidden/NoDisplay.
#
# Run it after a fresh install to populate wrappers for your curated list.

set -euo pipefail

SRC_DIRS=(
  /usr/share/applications
  /usr/local/share/applications
)
DST_DIR="${HOME}/.local/share/applications"

mkdir -p "$DST_DIR"

apps=(
  xfce4-settings-manager.desktop
  xfce-display-settings.desktop
  xfce4-mime-settings.desktop
  xfce-keyboard-settings.desktop
  xfce-mouse-settings.desktop
  thunar.desktop
  pavucontrol.desktop
  ristretto.desktop
  # add more as desired
)

get_field() {
  # Extract the first matching key across locales
  # Prefer unlocalized key; fallback to en_US/en_GB; then any.
  local key="$1" file="$2"
  awk -F= -v key="$key" '
    $1==key {print $2; found=1; exit}
    $1 ~ "^"key"\$$" { if (!first) { first=$2 } }
    END { if (!found && first) print first }
  ' "$file"
}

for app in "${apps[@]}"; do
  src=""
  for d in "${SRC_DIRS[@]}"; do
    if [[ -f "$d/$app" ]]; then src="$d/$app"; break; fi
  done
  if [[ -z "$src" ]]; then
    echo "Skip (not found): $app"
    continue
  fi

  name="$(get_field Name "$src")"
  exec="$(get_field Exec "$src" | sed 's/ *%[fFuUdDnNickvm]//g')"
  icon="$(get_field Icon "$src")"

  # Resolve binary path if possible
  bin="$(printf '%s\n' "$exec" | awk '{print $1}')"
  if command -v "$bin" >/dev/null 2>&1; then
    fullbin="$(command -v "$bin")"
    exec="${exec/$bin/$fullbin}"
  fi

  out="${DST_DIR}/${app%.desktop}-wrapper.desktop"
  cat > "$out" /dev/null 2>&1 && update-desktop-database "${DST_DIR%/}/.." || true
echo "Done."

> Can you check if the syntax is correct on this script. I got an error about the for loop.

#!/usr/bin/env bash

# make-wrappers.sh
# What it does:
# - Reads Name, Exec, Icon from the system .desktop.
# - Strips common field codes like %f (not needed for most cases).
# - Resolves Exec to a full path when possible.
# - Writes a -wrapper.desktop in your user applications dir without OnlyShowIn/Hidden/NoDisplay.
#
# Run it after a fresh install to populate wrappers for your curated list.

set -euo pipefail

SRC_DIRS=(
  /usr/share/applications
  /usr/local/share/applications
)
DST_DIR="${HOME}/.local/share/applications"

mkdir -p "$DST_DIR"

apps=(
  xfce4-settings-manager.desktop
  xfce-display-settings.desktop
  xfce4-mime-settings.desktop
  xfce-keyboard-settings.desktop
  xfce-mouse-settings.desktop
  thunar.desktop
  pavucontrol.desktop
  ristretto.desktop
  # add more as desired
)

get_field() {
  # Extract the first matching key across locales
  # Prefer unlocalized key; fallback to en_US/en_GB; then any.
  local key="$1" file="$2"
  awk -F= -v key="$key" '
    $1==key {print $2; found=1; exit}
    $1 ~ "^" key "\\[.*\\]$" { if (!first) { first=$2 } }
    END { if (!found && first) print first }
  ' "$file"
}

for app in "${apps[@]}"; do
  src=""
  for d in "${SRC_DIRS[@]}"; do
    if [[ -f "$d/$app" ]]; then src="$d/$app"; break; fi
  done
  if [[ -z "$src" ]]; then
    echo "Skip (not found): $app"
    continue
  fi

  name="$(get_field Name "$src")"
  exec="$(get_field Exec "$src" | sed 's/ *%[fFuUdDnNickvm]//g')"
  icon="$(get_field Icon "$src")"

  # Resolve binary path if possible
  bin="$(printf '%s\n' "$exec" | awk '{print $1}')"
  if command -v "$bin" >/dev/null 2>&1; then
    fullbin="$(command -v "$bin")"
    exec="${exec/$bin/$fullbin}"
  fi

  out="${DST_DIR}/${app%.desktop}-wrapper.desktop"
  cat > "$out" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec=$exec
Icon=$icon
EOF
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "${DST_DIR%/}/.." || true
done

echo "Done."


