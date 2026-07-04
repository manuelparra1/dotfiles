#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==============================================================================
# 1. OS-Specific Configuration & Path Resolution
# ==============================================================================
case "$(uname -s)" in
    Darwin)
        TYPORA_THEME_DIR="$HOME/Library/Application Support/abnerworks.Typora/themes"
        CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        ;;
    Linux)
        # Standard locations for Void, Arch, Debian, OpenSUSE flatpaks/native paths
        if [ -d "$HOME/.config/Typora/themes" ]; then
            TYPORA_THEME_DIR="$HOME/.config/Typora/themes"
        elif [ -d "$HOME/.var/app/io.typora.Typora/config/Typora/themes" ]; then
            TYPORA_THEME_DIR="$HOME/.var/app/io.typora.Typora/config/Typora/themes"
        else
            TYPORA_THEME_DIR="$HOME/.config/Typora/themes"
        fi
        
        # Look for Chrome or Chromium binaries across common path locations
        CHROME_BIN=$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser)
        ;;
    *)
        echo "Error: Unsupported operating system." >&2
        exit 1
        ;;
esac

# ==============================================================================
# 2. Input Validation
# ==============================================================================
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $(basename "$0") <markdown_file.md> [theme_name]" >&2
    echo "Example: $(basename "$0") notes.md google-sans-flex" >&2
    exit 1
fi

INPUT_MD="$1"
# Default to google-sans-flex if no second argument is provided
THEME_NAME="${2:-google-sans-flex}"

if [ ! -f "$INPUT_MD" ]; then
    echo "Error: Input file '$INPUT_MD' not found." >&2
    exit 1
fi

if [ -z "$CHROME_BIN" ] || [ ! -x "$CHROME_BIN" ]; then
    echo "Error: Google Chrome / Chromium executable not found." >&2
    exit 1
fi

# ==============================================================================
# 3. Path Extractions & Scratch Space Setup
# ==============================================================================
BASE_NAME=$(basename "$INPUT_MD" .md)
DIR_NAME=$(dirname "$INPUT_MD")
TARGET_HTML="$DIR_NAME/${BASE_NAME}.html"
TARGET_PDF="$DIR_NAME/${BASE_NAME}.pdf"

THEME_CSS="${TYPORA_THEME_DIR}/${THEME_NAME}.css"
THEME_ASSET_DIR="${TYPORA_THEME_DIR}/${THEME_NAME}"

if [ ! -f "$THEME_CSS" ]; then
    echo "Error: Theme CSS not found at: $THEME_CSS" >&2
    exit 1
fi

# Create a trap to clean up working copies inside the local workspace on exit
TMP_CSS=""
TMP_ASSET_DIR=""

cleanup() {
    [ -n "$TMP_CSS" ] && [ -f "$TMP_CSS" ] && rm -f "$TMP_CSS"
    [ -n "$TMP_ASSET_DIR" ] && [ -d "$TMP_ASSET_DIR" ] && rm -rf "$TMP_ASSET_DIR"
}
trap cleanup EXIT

# ==============================================================================
# 4. Asset Isolation (Handles relative local fonts like ./google-sans-flex)
# ==============================================================================
echo "Compiling using theme: $THEME_NAME"

# Copy CSS and asset sub-directories locally into the workspace so Pandoc/Chrome can see them
TMP_CSS="$DIR_NAME/${THEME_NAME}.css"
cp "$THEME_CSS" "$TMP_CSS"

if [ -d "$THEME_ASSET_DIR" ]; then
    TMP_ASSET_DIR="$DIR_NAME/${THEME_NAME}"
    cp -R "$THEME_ASSET_DIR" "$TMP_ASSET_DIR"
fi

# ==============================================================================
# 5. Pipeline Execution
# ==============================================================================
echo "Step 1: Compiling standalone HTML via Pandoc..."
pandoc "$INPUT_MD" \
  --standalone \
  --css "$(basename "$TMP_CSS")" \
  --resource-path=".:${DIR_NAME}/images" \
  -o "$TARGET_HTML"

echo "Step 2: Driving headless Chrome to generate PDF layout..."
"$CHROME_BIN" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$TARGET_PDF" \
  "file://$(cd "$DIR_NAME" && pwd)/$(basename "$TARGET_HTML")" \
  2>/tmp/chrome-pdf.log

echo "Success! Output generated: $TARGET_PDF"
