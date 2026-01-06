#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/toggle_backblaze_settings.conf"

# Load configuration from .conf file if it exists
if [ -f "$CONFIG_FILE" ]; then
    # Source the config file, ignoring errors from commented lines
    source "$CONFIG_FILE" 2>/dev/null || true
fi

# Set default destination (hardcoded as this is standard on macOS)
DESTINATION="/Library/Backblaze.bzpkg/bzdata/bzinfo.xml"

# Set defaults based on script directory if not configured
if [ -z "$MANUAL_BACKUP" ]; then
    MANUAL_BACKUP="$SCRIPT_DIR/MyOnlyWhenClickBzinfo.xml"
fi

if [ -z "$CONTINUOUS_BACKUP" ]; then
    CONTINUOUS_BACKUP="$SCRIPT_DIR/myContinouslyBzinfo.xml"
fi

if [ -z "$LOG_FILE" ]; then
    LOG_FILE="$SCRIPT_DIR/backblaze_settings_toggle.log"
fi

# Source the setup file for first-run logic
SETUP_FILE="$SCRIPT_DIR/setup_settings_files.sh"
if [ -f "$SETUP_FILE" ]; then
    source "$SETUP_FILE"
fi

# Function to log the action
log_action() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local action="$1"
    local source_file="$2"
    echo "[$timestamp] $action: Copied $(basename "$source_file") to bzinfo.xml" >> "$LOG_FILE"
}

# Function to determine which backup type is currently active
get_current_backup_type() {
    if [ ! -f "$DESTINATION" ]; then
        echo "unknown"
        return
    fi
    
    if grep -q 'backup_schedule_type="only_when_click_backup_now"' "$DESTINATION" 2>/dev/null; then
        echo "manual"
    elif grep -q 'backup_schedule_type="continuously"' "$DESTINATION" 2>/dev/null; then
        echo "continuous"
    else
        echo "unknown"
    fi
}

# Function to display current backup status
show_status() {
    local current_type=$(get_current_backup_type)
    
    if [ "$current_type" = "manual" ]; then
        echo "Backblaze is currently set to: MANUAL backup (only when click backup now)"
        exit 0
    elif [ "$current_type" = "continuous" ]; then
        echo "Backblaze is currently set to: CONTINUOUS backup"
        exit 0
    else
        echo "Error: Could not determine current backup status. The destination file may not exist or be unreadable." >&2
        exit 1
    fi
}

# Function to display usage information
show_usage() {
    local script_name=$(basename "$0")
    cat << EOF
Usage: $script_name [OPTIONS] [manual|continuous]

Toggle or set Backblaze backup schedule between manual and continuous modes.

OPTIONS:
    -h, --help      Show this help message and exit
    -s, --status    Show current backup status and exit

ARGUMENTS:
    (none)          Toggle between manual and continuous backup settings
    manual          Set to manual backup (only when click backup now)
    continuous      Set to continuous backup

EXAMPLES:
    (if run from the script's directory, otherwise specify the full path)
    
    ./$script_name                    # Toggle between manual and continuous
    ./$script_name manual             # Set to manual backup
    ./$script_name continuous         # Set to continuous backup
    ./$script_name -s                 # Show current backup status
    ./$script_name --status           # Show current backup status
    ./$script_name -h                 # Show this help message

The script copies one of two pre-configured settings files to the Backblaze
configuration file and logs each action with a timestamp.

Configuration files:
    Manual:    $(basename "$MANUAL_BACKUP")
    Continuous: $(basename "$CONTINUOUS_BACKUP")
    Destination: $DESTINATION
    Log file:   $LOG_FILE
EOF
}

# Function to copy settings file
copy_settings() {
    local source_file="$1"
    local backup_type="$2"
    
    if [ ! -f "$source_file" ]; then
        echo "Error: Source file not found: $source_file" >&2
        exit 1
    fi
    
    # Check if we have permission to write to destination
    if [ ! -w "$DESTINATION" ] && [ -f "$DESTINATION" ]; then
        echo "Error: No write permission to $DESTINATION. This script may need to be run with sudo." >&2
        exit 1
    fi
    
    # Copy the file
    if cp "$source_file" "$DESTINATION" 2>/dev/null; then
        log_action "SET" "$source_file"
        echo "Successfully set Backblaze to $backup_type backup mode"
    else
        echo "Error: Failed to copy $source_file to $DESTINATION. This script may need to be run with sudo." >&2
        exit 1
    fi
}

# Main script logic
# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Check for status flag
if [ "$1" = "-s" ] || [ "$1" = "--status" ]; then
    show_status
fi

# Check if settings files exist, create them if needed
check_and_create_settings_files

if [ $# -eq 0 ]; then
    # No arguments: toggle between the two settings
    current_type=$(get_current_backup_type)
    
    if [ "$current_type" = "manual" ]; then
        # Currently manual, switch to continuous
        copy_settings "$CONTINUOUS_BACKUP" "continuous"
    elif [ "$current_type" = "continuous" ]; then
        # Currently continuous, switch to manual
        copy_settings "$MANUAL_BACKUP" "manual"
    else
        # Unknown state, default to continuous
        echo "Warning: Could not determine current backup type. Defaulting to continuous." >&2
        copy_settings "$CONTINUOUS_BACKUP" "continuous"
    fi
else
    # Arguments provided: use them to specify which settings file to use
    case "$1" in
        manual|Manual|MANUAL|only_when_click|click)
            copy_settings "$MANUAL_BACKUP" "manual"
            ;;
        continuous|Continuous|CONTINUOUS|auto|automatic|Automatic|AUTOMATIC)
            copy_settings "$CONTINUOUS_BACKUP" "continuous"
            ;;
        *)
            echo "Error: Invalid argument '$1'" >&2
            echo "" >&2
            show_usage >&2
            exit 1
            ;;
    esac
fi

