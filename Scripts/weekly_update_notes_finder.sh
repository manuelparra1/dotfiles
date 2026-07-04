#!/usr/bin/env bash
set -euo pipefail

# Check if ripgrep is installed
command -v rg >/dev/null 2>&1 || { 
    printf '[✗] Ripgrep (rg) is not installed. Please install it (e.g., brew install ripgrep) to run this script.\n' >&2
    exit 1
}

BASE_DIR="/Users/dusts/aston/Notes/Obsidian/aston"
# $(pwd) captures the directory you run the command FROM, not where the script lives.
OUTPUT_DIR="$(pwd)/found-files"

# ---- logging helpers ----
log()  { printf '[%s]  %s\n'  "$(date +%H:%M:%S)" "$*" >&2; }
err()  { printf '[%s] ✗  %s\n' "$(date +%H:%M:%S)" "$*" >&2; }

parse_date() {
    local in="$1" out
    for fmt in "%m-%d-%y" "%m-%d-%Y" "%m/%d/%y" "%m/%d/%Y" "%Y-%m-%d"; do
        if out=$(date -j -f "$fmt" "$in" +%Y-%m-%d 2>/dev/null); then
            echo "$out"; return 0
        fi
    done
    if out=$(date -d "$in" +%Y-%m-%d 2>/dev/null); then
        echo "$out"; return 0
    fi
    err "Can't parse date '$in'"; exit 1
}

# ---- args ----
if [[ $# -eq 1 && "$1" == *to* ]]; then
    start_raw=$(echo "$1" | awk -F'to' '{print $1}' | xargs)
    end_raw=$(echo "$1"   | awk -F'to' '{print $2}' | xargs)
elif [[ $# -eq 2 ]]; then
    start_raw="$1"; end_raw="$2"
else
    echo "Usage: $0 4-13-26 4-15-26"; exit 1
fi

start_date=$(parse_date "$start_raw")
end_date=$(parse_date "$end_raw")

log "Vault  : $BASE_DIR"
log "Range  : $start_date → $end_date"
log "Output : $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cd "$BASE_DIR" || { err "Cannot cd into $BASE_DIR"; exit 1; }

echo ""
log "Searching vault with Ripgrep..."

count=0
date_lookups=0
cache_hits=0
t_start=$(date +%s)

while IFS= read -r line; do
    # Extract the date (last 10 chars) and filepath (everything before the last colon)
    created_date="${line: -10}"
    filepath="${line%:*}"

    # Check date range
    if [[ ! "$created_date" < "$start_date" && ! "$created_date" > "$end_date" ]]; then
        short="${filepath#./}"
        
        # macOS Bash 3.2 Compatible Cache: Convert "2026-04-13" to "2026_04_13" for variable naming
        safe_date="${created_date//-/_}"
        cache_var="day_cache_$safe_date"
        
        # Look up the weekday using indirect variable expansion (!cache_var)
        if [[ -z "${!cache_var:-}" ]]; then
            ((date_lookups++)) || true
            if day_name=$(date -j -f "%Y-%m-%d" "$created_date" "+%A" 2>/dev/null) || \
               day_name=$(date -d "$created_date" "+%A" 2>/dev/null); then
                eval "$cache_var=\"\$day_name\""
            else
                eval "$cache_var=\"Unknown-Day\""
            fi
        else
            ((cache_hits++)) || true
        fi
        
        day_of_week="${!cache_var}"
        
        # Build destination using the cached day name
        dest="$OUTPUT_DIR/$day_of_week/$short"
        
        mkdir -p "$(dirname "$dest")"
        cp "$filepath" "$dest"
        
        ((count++)) || true
        printf "\r[⏳] Fast-copying... %d files matched | %d cached dates" "$count" "$cache_hits" >&2
    fi

# CHANGED: Added -H (--with-filename) to forcefully print the file path
done < <(rg -I -H -o --no-heading --no-line-number -r '$1' '^created:\s*"?([0-9]{4}-[0-9]{2}-[0-9]{2})' -g "*.md" .)

elapsed=$(( $(date +%s) - t_start ))

echo ""
echo ""

log "════════════════════════════════════════════"
log "Finished in ${elapsed}s"
log "  Files Copied     : $count"
log "  System Date calls: $date_lookups (Slow subshells)"
log "  Cache Hits       : $cache_hits (Instant memory loads)"
log "  Output directory : $OUTPUT_DIR"
log "════════════════════════════════════════════"
