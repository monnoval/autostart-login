#!/bin/bash
#
# Install Flatpak Auto-Update systemd services
# Run this script to set up and configure the services
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
    echo "✓ Loaded configuration from config.sh"
else
    echo "⚠️  No config.sh found, using defaults"
    LOG_DIR="$SCRIPT_DIR"
    LOGIN_DELAY="1min"
fi

# Systemd user directory (respects XDG_CONFIG_HOME)
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

echo ""
echo "Installing Flatpak Auto-Update systemd service..."
echo "  Log directory: $LOG_DIR"
echo "  Login delay: $LOGIN_DELAY"
echo ""

# Create systemd user directory if it doesn't exist
mkdir -p "$SYSTEMD_USER_DIR"

# Remove old service files if they exist
echo "Cleaning up old service files..."
rm -f "$SYSTEMD_USER_DIR/flatpak-autoupdate.service"
rm -f "$SYSTEMD_USER_DIR/flatpak-autoupdate.timer"

# Generate service file with configured paths
echo "Generating service files from templates..."

# flatpak-autoupdate.service
sed "s|%SCRIPT_DIR%|$SCRIPT_DIR|g" \
    "$SCRIPT_DIR/flatpak-autoupdate.service" > "$SYSTEMD_USER_DIR/flatpak-autoupdate.service"

# flatpak-autoupdate.timer
sed "s|%LOGIN_DELAY%|$LOGIN_DELAY|g" \
    "$SCRIPT_DIR/flatpak-autoupdate.timer" > "$SYSTEMD_USER_DIR/flatpak-autoupdate.timer"

echo "✓ Service files generated"
echo ""

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$SCRIPT_DIR/flatpak-update-daily.sh"
echo "✓ Scripts are executable"
echo ""

# Reload systemd
echo "Reloading systemd..."
systemctl --user daemon-reload
echo "✓ Systemd reloaded"
echo ""

# Enable and start service
echo "Enabling service..."
systemctl --user enable flatpak-autoupdate.timer
echo "✓ Service enabled"
echo ""

# Start service
echo "Starting service..."
systemctl --user start flatpak-autoupdate.timer
echo "✓ Service started"
echo ""

# Show status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation complete! Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
systemctl --user list-timers flatpak-autoupdate.timer --no-pager
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation complete!"
echo ""
echo "Your flatpak auto-update service is now configured:"
echo "  • Runs automatically $LOGIN_DELAY after login"
echo "  • Updates flatpak packages only once per day"
echo "  • Desktop notifications on completion/failure"
echo "  • Logs stored in: $LOG_DIR"
echo ""

# Check for lingering
LINGER_STATUS=$(loginctl show-user $USER 2>/dev/null | grep "Linger=" | cut -d= -f2)
if [ "$LINGER_STATUS" != "yes" ]; then
    echo "ℹ️  Note: User lingering is NOT enabled."
    echo "   This is OK for login-triggered services."
    echo "   The update will run each time you log in."
    echo ""
fi

echo "Configuration: $SCRIPT_DIR/config.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next login, flatpak will auto-update if it hasn't run today."
echo ""
echo "To manually test the update script now, run:"
echo "  $SCRIPT_DIR/flatpak-update-daily.sh"
echo ""

