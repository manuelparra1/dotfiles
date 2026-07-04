#!/usr/bin/env bash

# ==============================================================================
# IMAGE BATCH PROCESSOR (Flexible Argument Order)
# usage: bash resizer.sh . -e jpg
# usage: bash resizer.sh -e jpg .
# ==============================================================================

# --- 1. STRICT MODE ---
set -euo pipefail

# --- 2. DEFAULTS ---
TARGET_SIZE="1920"
OUTPUT_DIR=""       
EXTENSION="png"
DRY_RUN=false
VERBOSE=false
PARALLEL_JOBS=1
FORCE=false         
INPUT_DIR=""        # Initialize empty

# --- 3. HELP MENU ---
usage() {
    echo "Usage: $(basename "$0") [OPTIONS] <DIRECTORY>"
    echo ""
    echo "Batch resize images in a specific directory."
    echo ""
    echo "Arguments:"
    echo "  <DIRECTORY>            The directory containing images (Required)"
    echo ""
    echo "Options:"
    echo "  -s, --size <width>     Target width in pixels (Default: 1920)"
    echo "  -o, --output <dir>     Output directory (Default: <INPUT_DIR>/converted)"
    echo "  -e, --ext <extension>  File extension to process (Default: png)"
    echo "  -j, --jobs <num>       Number of parallel jobs (Default: 1)"
    echo "  -f, --force            Overwrite existing output files"
    echo "  -d, --dry-run          Print commands without executing them"
    echo "  -v, --verbose          Enable verbose logging"
    echo "  -h, --help             Show this help message"
    echo ""
    exit 1
}

# --- 4. LOGGING HELPER ---
log() {
    if [ "$VERBOSE" = true ]; then
        echo "[LOG] $1"
    fi
}

# --- 5. ARGUMENT PARSING (ROBUST) ---
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -s|--size)
            TARGET_SIZE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -e|--ext)
            EXTENSION="$2"
            shift 2
            ;;
        -j|--jobs)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Error: Unknown option '$1'"
            usage
            ;;
        *)
            # POSITIONAL ARGUMENT (The Directory)
            # We check if we already found a directory to prevent multiple inputs
            if [[ -n "$INPUT_DIR" ]]; then
                echo "Error: Multiple directories specified. Only one allowed."
                echo "First: $INPUT_DIR"
                echo "Second: $1"
                exit 1
            fi
            
            INPUT_DIR="$1"
            shift # Shift past the directory
            ;;
    esac
done

# --- 6. INPUT/OUTPUT VALIDATION ---

# Validate Input (We check the variable we set inside the loop)
if [[ -z "$INPUT_DIR" ]]; then
    echo "Error: No directory specified."
    usage
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: '$INPUT_DIR' is not a valid directory."
    exit 1
fi

# Dynamic Output Logic
if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="${INPUT_DIR%/}/converted"
fi

# Check Dependencies
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick (magick) is not installed." >&2
    exit 1
fi

# --- 7. EXECUTION PREP ---

log "Configuration:"
log "  Input:  $INPUT_DIR"
log "  Output: $OUTPUT_DIR"
log "  Target: *.$EXTENSION -> ${TARGET_SIZE}px width"
log "  Mode:   Force=$FORCE, DryRun=$DRY_RUN, Jobs=$PARALLEL_JOBS"

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$OUTPUT_DIR"
fi

shopt -s nullglob

# --- 8. MAIN LOOP ---

count=0
skipped=0

for file in "$INPUT_DIR"/*."$EXTENSION"; do
    
    if [ -f "$file" ]; then
        count=$((count + 1))
        
        filename=$(basename "$file" ."$EXTENSION")
        new_filename="${filename}_${TARGET_SIZE}w.${EXTENSION}"
        output_path="$OUTPUT_DIR/$new_filename"

        # IDEMPOTENCY CHECK
        if [ "$FORCE" = false ] && [ -f "$output_path" ]; then
            log "Skipping $filename (Output exists)"
            skipped=$((skipped + 1))
            continue
        fi

        cmd="magick '$file' -resize ${TARGET_SIZE}x '$output_path'"

        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] $cmd"
        else
            log "Processing: $filename"
            
            if [ "$PARALLEL_JOBS" -gt 1 ]; then
                magick "$file" -resize "${TARGET_SIZE}x" "$output_path" &
                if [[ $(jobs -r -p | wc -l) -ge $PARALLEL_JOBS ]]; then
                    wait -n
                fi
            else
                magick "$file" -resize "${TARGET_SIZE}x" "$output_path"
            fi
        fi
    fi
done

wait

# --- 9. SUMMARY ---
if [ "$DRY_RUN" = false ]; then
    echo "----------------------------------------"
    echo "Batch Complete."
    echo "Found: $count | Skipped: $skipped | Processed: $((count - skipped))"
    echo "Output Location: $OUTPUT_DIR"
fi
