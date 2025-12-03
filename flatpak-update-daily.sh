#!/bin/bash
#
# Flatpak Daily Auto-Update Script
# Only runs once per day, checking timestamp file
#

set -e

# Machine-local state directory (not in project, so each machine has its own)
STATE_DIR="$HOME/.local/share/flatpak-autoupdate"
TIMESTAMP_FILE="$STATE_DIR/last-update"
TODAY=$(date +%Y-%m-%d)

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Check if we've already updated today
if [ -f "$TIMESTAMP_FILE" ]; then
    LAST_UPDATE=$(cat "$TIMESTAMP_FILE")
    if [ "$LAST_UPDATE" = "$TODAY" ]; then
        echo "$(date): Flatpak already updated today. Skipping."
        exit 0
    fi
fi

# Run flatpak update
echo "$(date): Starting flatpak update..."

if flatpak update -y; then
    echo "$(date): Flatpak update completed successfully."
    
    # Save today's date as the last update timestamp
    echo "$TODAY" > "$TIMESTAMP_FILE"
    
    # Optional: Send notification on success
    if command -v notify-send &> /dev/null; then
        notify-send "Flatpak Update" "Flatpak packages updated successfully" -i software-update-available
    elif command -v kdialog &> /dev/null; then
        kdialog --passivepopup "Flatpak packages updated successfully" 5 --title "Flatpak Update"
    fi
else
    echo "$(date): Flatpak update failed!"
    
    # Send notification on failure
    if command -v notify-send &> /dev/null; then
        notify-send -u critical "Flatpak Update Failed" "Run: journalctl --user -u flatpak-autoupdate.service" -i dialog-error
    elif command -v kdialog &> /dev/null; then
        kdialog --passivepopup "Flatpak update failed! Check journalctl for details" 10 --title "Flatpak Update Error"
    fi
    
    exit 1
fi
