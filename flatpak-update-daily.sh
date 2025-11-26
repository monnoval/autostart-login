#!/bin/bash
#
# Flatpak Daily Auto-Update Script
# Only runs once per day, checking timestamp file
#

set -e

# Load configuration from the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    # Default configuration - use script directory
    LOG_DIR="$SCRIPT_DIR"
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

TIMESTAMP_FILE="$LOG_DIR/last-update"
LOG_FILE="$LOG_DIR/update.log"
TODAY=$(date +%Y-%m-%d)

# Check if we've already updated today
if [ -f "$TIMESTAMP_FILE" ]; then
    LAST_UPDATE=$(cat "$TIMESTAMP_FILE")
    if [ "$LAST_UPDATE" = "$TODAY" ]; then
        echo "$(date): Flatpak already updated today. Skipping." | tee -a "$LOG_FILE"
        exit 0
    fi
fi

# Run flatpak update
echo "$(date): Starting flatpak update..." | tee -a "$LOG_FILE"

if flatpak update -y >> "$LOG_FILE" 2>&1; then
    echo "$(date): Flatpak update completed successfully." | tee -a "$LOG_FILE"
    
    # Save today's date as the last update timestamp
    echo "$TODAY" > "$TIMESTAMP_FILE"
    
    # Optional: Send notification on success
    if command -v notify-send &> /dev/null; then
        notify-send "Flatpak Update" "Flatpak packages updated successfully" -i software-update-available
    elif command -v kdialog &> /dev/null; then
        kdialog --passivepopup "Flatpak packages updated successfully" 5 --title "Flatpak Update"
    fi
else
    echo "$(date): Flatpak update failed!" | tee -a "$LOG_FILE"
    
    # Send notification on failure
    if command -v notify-send &> /dev/null; then
        notify-send -u critical "Flatpak Update Failed" "Check logs at $LOG_FILE" -i dialog-error
    elif command -v kdialog &> /dev/null; then
        kdialog --passivepopup "Flatpak update failed! Check logs at $LOG_FILE" 10 --title "Flatpak Update Error"
    fi
    
    exit 1
fi

