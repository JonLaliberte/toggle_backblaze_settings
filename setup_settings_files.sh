#!/bin/bash

# Function to check and create settings files if they don't exist
# This is first-run logic to help users set up the required XML configuration files
check_and_create_settings_files() {
    local manual_exists=false
    local continuous_exists=false
    
    # Check if files exist
    if [ -f "$MANUAL_BACKUP" ]; then
        manual_exists=true
    fi
    
    if [ -f "$CONTINUOUS_BACKUP" ]; then
        continuous_exists=true
    fi
    
    # If both files exist, no action needed
    if [ "$manual_exists" = true ] && [ "$continuous_exists" = true ]; then
        return 0
    fi

    if [ ! -t 0 ]; then
        echo "Error: Settings files are missing and setup requires an interactive terminal." >&2
        echo "Run this script interactively once to generate the required settings files." >&2
        return 1
    fi
    
    # At least one file is missing, prompt user
    echo "Error: Required settings files are missing." >&2
    echo "" >&2
    if [ "$manual_exists" = false ]; then
        echo "  Missing: $(basename "$MANUAL_BACKUP")" >&2
    fi
    if [ "$continuous_exists" = false ]; then
        echo "  Missing: $(basename "$CONTINUOUS_BACKUP")" >&2
    fi
    echo "" >&2
    echo "To create these files, please follow these steps:" >&2
    echo "  1. Open Backblaze Settings" >&2
    echo "  2. Go to the 'Schedule' section" >&2
    echo "  3. Change the Backup Schedule to 'Only When I Click <Backup Now>'" >&2
    echo "  4. Click the 'OK' button" >&2
    echo "  5. Close the Backblaze settings window" >&2
    echo "" >&2
    echo "This will create a bzinfo.xml file that the script can use to generate" >&2
    echo "the required settings files." >&2
    echo "" >&2
    read -p "Press Enter when you have completed these steps..."
    
    # Check if the bzinfo.xml file exists
    local source_bzinfo="/Library/Backblaze.bzpkg/bzdata/bzinfo.xml"
    if [ ! -f "$source_bzinfo" ]; then
        echo "Error: Could not find $source_bzinfo" >&2
        echo "Please make sure you followed the steps above and that Backblaze is installed." >&2
        return 1
    fi
    
    # Verify it has the expected backup_schedule_type
    if ! grep -q 'backup_schedule_type="only_when_click_backup_now"' "$source_bzinfo" 2>/dev/null; then
        echo "Warning: The bzinfo.xml file does not appear to have 'only_when_click_backup_now' schedule type." >&2
        echo "Please make sure you set the schedule to 'Only When I Click <Backup Now>' in Backblaze settings." >&2
        read -p "Do you want to continue anyway? (y/N): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Ask for permission to create the files
    echo "" >&2
    echo "The script will now:" >&2
    echo "  1. Copy $source_bzinfo to $(basename "$MANUAL_BACKUP")" >&2
    echo "  2. Create $(basename "$CONTINUOUS_BACKUP") with continuous backup settings" >&2
    echo "" >&2
    read -p "Is it OK to create these files? (Y/n): " create_files
    create_files=${create_files:-Y}
    
    if [[ ! "$create_files" =~ ^[Yy]$ ]]; then
        echo "Aborted. The script cannot run without these settings files." >&2
        return 1
    fi
    
    # Create the manual backup file
    if [ "$manual_exists" = false ]; then
        if cp "$source_bzinfo" "$MANUAL_BACKUP" 2>/dev/null; then
            echo "Created: $(basename "$MANUAL_BACKUP")" >&2
        else
            echo "Error: Failed to create $MANUAL_BACKUP" >&2
            return 1
        fi
    fi
    
    # Create the continuous backup file
    if [ "$continuous_exists" = false ]; then
        # Use the manual backup file as source if it was just created, otherwise use the source bzinfo
        local source_for_continuous="$MANUAL_BACKUP"
        if [ "$manual_exists" = true ]; then
            source_for_continuous="$source_bzinfo"
        fi
        
        # Copy and modify the backup_schedule_type
        if sed 's/backup_schedule_type="only_when_click_backup_now"/backup_schedule_type="continuously"/g' "$source_for_continuous" > "$CONTINUOUS_BACKUP" 2>/dev/null; then
            if grep -q 'backup_schedule_type="continuously"' "$CONTINUOUS_BACKUP" 2>/dev/null; then
                echo "Created: $(basename "$CONTINUOUS_BACKUP")" >&2
            else
                echo "Error: Failed to verify continuous schedule in $CONTINUOUS_BACKUP" >&2
                echo "Please confirm your source settings include backup_schedule_type=\"only_when_click_backup_now\"." >&2
                return 1
            fi
        else
            echo "Error: Failed to create $CONTINUOUS_BACKUP" >&2
            return 1
        fi
    fi
    
    echo "" >&2
    echo "Settings files created successfully!" >&2
    echo "" >&2
    return 0
}

