#!/bin/bash

# Dotfiles Backup Script
# Usage: ./backup-dotfiles.sh [-o output_directory]

# Default destination is current directory
DEST_DIR="."
SCRIPT_NAME=$(basename "$0")

# Create log file with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="dotfiles_backup_${TIMESTAMP}.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while getopts "o:h" opt; do
    case $opt in
        o)
            DEST_DIR="$OPTARG"
            ;;
        h)
            echo "Usage: $SCRIPT_NAME [-o output_directory]"
            echo "  -o: Specify output directory (default: current directory)"
            echo "  -h: Show this help message"
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

# Initialize log file
echo "=== Dotfiles Backup Log ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Script: $SCRIPT_NAME" >> "$LOG_FILE"
echo "Destination: $DEST_DIR" >> "$LOG_FILE"
echo "User: $(whoami)@$(hostname)" >> "$LOG_FILE"
echo "Working Directory: $(pwd)" >> "$LOG_FILE"
echo "=========================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Function to print colored output and log
print_status() {
    local color=$1
    local message=$2
    local log_level=${3:-"INFO"}
    
    # Print to terminal with color
    echo -e "${color}${message}${NC}"
    
    # Log to file without color codes
    echo "[$log_level] $(date '+%H:%M:%S') - $message" >> "$LOG_FILE"
}

# Function to log errors/exceptions
log_error() {
    local message=$1
    print_status $RED "❌ ERROR: $message" "ERROR"
}

# Function to log warnings
log_warning() {
    local message=$1
    print_status $YELLOW "⚠️  WARNING: $message" "WARN"
}

# Function to copy with rsync, excluding .git directories
# Enhanced function with better delta sync
safe_copy() {
    local src=$1
    local dest=$2
    local item_name=$3
    
    print_status $BLUE "🔍 Checking $item_name at: $src"
    
    if [[ -e "$src" ]]; then
        print_status $BLUE "📁 Copying $item_name..."
        
        if [[ -d "$src" ]]; then
            # Enhanced rsync with delta sync features
            echo "[$(date '+%H:%M:%S')] RSYNC Command: rsync -avz --partial --progress --itemize-changes --update --exclude='.git/' '$src' '$dest/'" >> "$LOG_FILE"
            if rsync -avz --partial --progress --itemize-changes --update --exclude='.git/' "$src" "$dest/" 2>>"$LOG_FILE"; then
                print_status $GREEN "✅ Successfully synced $item_name"
                return 0
            else
                log_error "Failed to sync directory $item_name (rsync failed)"
                return 1
            fi
        else
            # For single files, still use rsync for consistency
            echo "[$(date '+%H:%M:%S')] RSYNC Command: rsync -avz --partial --progress --itemize-changes --update '$src' '$dest/'" >> "$LOG_FILE"
            if rsync -avz --partial --progress --itemize-changes --update "$src" "$dest/" 2>>"$LOG_FILE"; then
                print_status $GREEN "✅ Successfully synced $item_name"
                return 0
            else
                log_error "Failed to sync file $item_name (rsync failed)"
                return 1
            fi
        fi
    else
        log_warning "Skipping $item_name (not found at: $src)"
        return 1
    fi
}

# Function to detect window manager/desktop environment
detect_environment() {
    local wm_detected=""
    
    print_status $BLUE "🔍 Detecting environment..." "INFO"
    
    if [[ -d "$HOME/.config/hypr" ]]; then
        wm_detected="Hyprland"
        echo "[$(date '+%H:%M:%S')] Found: $HOME/.config/hypr" >> "$LOG_FILE"
    else
        echo "[$(date '+%H:%M:%S')] Not found: $HOME/.config/hypr" >> "$LOG_FILE"
    fi
    
    if [[ -d "$HOME/.config/i3" ]]; then
        wm_detected="${wm_detected:+$wm_detected, }i3"
        echo "[$(date '+%H:%M:%S')] Found: $HOME/.config/i3" >> "$LOG_FILE"
    else
        echo "[$(date '+%H:%M:%S')] Not found: $HOME/.config/i3" >> "$LOG_FILE"
    fi
    
    if [[ -n "$wm_detected" ]]; then
        print_status $BLUE "🖥️  Detected Window Manager(s): $wm_detected"
    else
        print_status $YELLOW "🖥️  No specific window managers detected"
    fi
}

# Create destination directory
print_status $BLUE "🚀 Starting dotfiles backup..."
print_status $BLUE "📂 Destination: $(realpath "$DEST_DIR")"
print_status $BLUE "📄 Log file: $LOG_FILE"

if ! mkdir -p "$DEST_DIR" 2>>"$LOG_FILE"; then
    log_error "Failed to create destination directory: $DEST_DIR"
    exit 1
fi

# Detect current environment
detect_environment

# Initialize counters
copied_count=0
skipped_count=0

print_status $BLUE "\n📋 Copying main dotfiles..."

# Main dotfiles to copy (using simple arrays instead of associative)
main_files=(
    "$HOME/.zshrc:zshrc"
    "$HOME/.tmux.conf:tmux.conf" 
    "$HOME/.zsh_history:zsh_history"
    "$HOME/.bliss_dircolors:bliss_dircolors"
)

echo "" >> "$LOG_FILE"
echo "=== MAIN FILES SECTION ===" >> "$LOG_FILE"

for item in "${main_files[@]}"; do
    src="${item%:*}"
    name="${item#*:}"
    print_status $BLUE "\n--- Processing: $name ---"
    if safe_copy "$src" "$DEST_DIR" "$name"; then
        ((copied_count++))
    else
        ((skipped_count++))
    fi
done

print_status $BLUE "\n📁 Copying main directories..."

# Main directories to copy
main_dirs=(
    "$HOME/.themes:themes directory"
    "$HOME/.fonts:fonts directory"
)

echo "" >> "$LOG_FILE"
echo "=== MAIN DIRECTORIES SECTION ===" >> "$LOG_FILE"

for item in "${main_dirs[@]}"; do
    src="${item%:*}"
    name="${item#*:}"
    print_status $BLUE "\n--- Processing: $name ---"
    if safe_copy "$src" "$DEST_DIR" "$name"; then
        ((copied_count++))
    else
        ((skipped_count++))
    fi
done

print_status $BLUE "\n⚙️  Copying config directories..."

# Create .config directory in destination
if ! mkdir -p "$DEST_DIR/.config" 2>>"$LOG_FILE"; then
    log_error "Failed to create .config directory in destination"
fi

# Config directories and files to copy
config_items=(
    "$HOME/.config/Typora:Typora config"
    "$HOME/.config/ghostty:Ghostty terminal config"
    "$HOME/.config/nvim:Neovim config"
    "$HOME/.config/zsh:ZSH config"
    "$HOME/.config/i3:i3 window manager config"
    "$HOME/.config/i3blocks:i3blocks config"
    "$HOME/.config/gtk-3.0:GTK-3.0 theming config"
    "$HOME/.config/hypr:Hyprland config"
    "$HOME/.config/bat:Bat syntax highlighter config"
    "$HOME/.config/eww:EWW widgets config"
    "$HOME/.config/kitty:Kitty terminal config"
    "$HOME/.config/rofi:Rofi launcher config"
    "$HOME/.config/wofi:Wofi launcher config"
    "$HOME/.config/starship.toml:Starship prompt config"
)

echo "" >> "$LOG_FILE"
echo "=== CONFIG ITEMS SECTION ===" >> "$LOG_FILE"

for item in "${config_items[@]}"; do
    src="${item%:*}"
    name="${item#*:}"
    print_status $BLUE "\n--- Processing: $name ---"
    if safe_copy "$src" "$DEST_DIR/.config" "$name"; then
        ((copied_count++))
    else
        ((skipped_count++))
    fi
done

# Create a metadata file with backup info
print_status $BLUE "\n📝 Creating backup metadata..."

if ! cat > "$DEST_DIR/backup-info.txt" << EOF
Dotfiles Backup Information
==========================
Backup Date: $(date)
Source Machine: $(hostname)
User: $(whoami)
OS: $(uname -s -r)
Shell: $SHELL
Log File: $LOG_FILE

Backup Statistics:
- Files/Directories Copied: $copied_count
- Items Skipped (not found): $skipped_count

Window Manager Detection:
$(if [[ -d "$HOME/.config/hypr" ]]; then echo "- Hyprland detected"; fi)
$(if [[ -d "$HOME/.config/i3" ]]; then echo "- i3 detected"; fi)

Desktop Environment Tools:
$(if [[ -d "$HOME/.config/eww" ]]; then echo "- EWW (Hyprland companion)"; fi)
$(if [[ -d "$HOME/.config/wofi" ]]; then echo "- Wofi (Hyprland launcher)"; fi)
$(if [[ -d "$HOME/.config/i3blocks" ]]; then echo "- i3blocks (i3 status bar)"; fi)
$(if [[ -d "$HOME/.config/rofi" ]]; then echo "- Rofi (i3 launcher)"; fi)

Universal Tools:
$(if [[ -f "$HOME/.zshrc" ]]; then echo "- ZSH shell"; fi)
$(if [[ -d "$HOME/.config/nvim" ]]; then echo "- Neovim"; fi)
$(if [[ -d "$HOME/.config/kitty" ]]; then echo "- Kitty terminal"; fi)
$(if [[ -d "$HOME/.config/ghostty" ]]; then echo "- Ghostty terminal"; fi)
$(if [[ -f "$HOME/.tmux.conf" ]]; then echo "- Tmux"; fi)
$(if [[ -d "$HOME/.config/bat" ]]; then echo "- Bat syntax highlighter"; fi)
$(if [[ -f "$HOME/.config/starship.toml" ]]; then echo "- Starship prompt"; fi)
EOF
then
    log_error "Failed to create backup-info.txt"
fi

# Final logging
echo "" >> "$LOG_FILE"
echo "=== BACKUP SUMMARY ===" >> "$LOG_FILE"
echo "Files/Directories Copied: $copied_count" >> "$LOG_FILE"
echo "Items Skipped: $skipped_count" >> "$LOG_FILE"
echo "Backup completed at: $(date)" >> "$LOG_FILE"

print_status $GREEN "\n🎉 Backup completed!"
print_status $GREEN "📊 Summary: $copied_count items copied, $skipped_count items skipped"
print_status $BLUE "📄 Backup information saved to: $DEST_DIR/backup-info.txt"
print_status $BLUE "📋 Full log saved to: $LOG_FILE"

# Show what was copied
print_status $BLUE "\n📋 Contents of backup directory:"
ls -la "$DEST_DIR" 2>>"$LOG_FILE" || log_error "Failed to list backup directory contents"

print_status $GREEN "\n🔄 Backup saved to: $(realpath "$DEST_DIR")"
print_status $YELLOW "\n💡 To view the full log: cat $LOG_FILE"
print_status $YELLOW "💡 Running this script again will UPDATE/OVERWRITE existing files"
