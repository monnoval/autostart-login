#!/bin/bash
#
# Install User Systemd Services
# Run this script to set up and configure the services
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
INSTALL_FLATPAK=true
INSTALL_XREMAP=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --flatpak-only)
            INSTALL_XREMAP=false
            shift
            ;;
        --xremap-only)
            INSTALL_FLATPAK=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--flatpak-only | --xremap-only]"
            exit 1
            ;;
    esac
done

# Load configuration
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
    echo "✓ Loaded configuration from config.sh"
else
    echo "⚠️  No config.sh found, using defaults"
    LOGIN_DELAY="4min"
    XREMAP_BIN="%h/.cargo/bin/xremap"
    XREMAP_CONFIG="%h/.config/xremap/config.yml"
    XREMAP_DEVICES=""
fi

# Systemd user directory (respects XDG_CONFIG_HOME)
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

echo ""
echo "Installing User Systemd Services..."
echo ""

# Create systemd user directory if it doesn't exist
mkdir -p "$SYSTEMD_USER_DIR"

# ========================================
# Install Flatpak Auto-Update Service
# ========================================
if [ "$INSTALL_FLATPAK" = true ]; then
    echo "━━━ Flatpak Auto-Update ━━━"
    echo "  Login delay: $LOGIN_DELAY"
    echo "  State dir: ~/.local/share/flatpak-autoupdate/"
    echo ""
    
    # Remove old service files if they exist
    echo "Cleaning up old flatpak service files..."
    rm -f "$SYSTEMD_USER_DIR/flatpak-autoupdate.service"
    rm -f "$SYSTEMD_USER_DIR/flatpak-autoupdate.timer"
    
    # Generate service files with configured paths
    echo "Generating flatpak service files..."
    sed "s|%SCRIPT_DIR%|$SCRIPT_DIR|g" \
        "$SCRIPT_DIR/flatpak-autoupdate.service" > "$SYSTEMD_USER_DIR/flatpak-autoupdate.service"
    
    sed "s|%LOGIN_DELAY%|$LOGIN_DELAY|g" \
        "$SCRIPT_DIR/flatpak-autoupdate.timer" > "$SYSTEMD_USER_DIR/flatpak-autoupdate.timer"
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR/flatpak-update-daily.sh"
    
    echo "✓ Flatpak service files generated"
    echo ""
fi

# ========================================
# Install Xremap Service
# ========================================
if [ "$INSTALL_XREMAP" = true ]; then
    echo "━━━ Xremap Keyboard/Mouse Remapper ━━━"
    echo "  Binary: $XREMAP_BIN"
    echo "  Config: $XREMAP_CONFIG"
    echo "  Devices: ${XREMAP_DEVICES:-"(all devices)"}"
    echo ""
    
    # Remove old service file if it exists
    echo "Cleaning up old xremap service file..."
    rm -f "$SYSTEMD_USER_DIR/xremap.service"
    
    # Generate service file with configured paths
    echo "Generating xremap service file..."
    # Build device flag only if XREMAP_DEVICES is set
    if [ -n "$XREMAP_DEVICES" ]; then
        # Escape backslashes for sed (so \s becomes \\s in the output)
        XREMAP_DEVICES_ESCAPED="${XREMAP_DEVICES//\\/\\\\}"
        XREMAP_DEVICE_FLAG="--device=$XREMAP_DEVICES_ESCAPED"
    else
        XREMAP_DEVICE_FLAG=""
    fi
    sed -e "s|%XREMAP_BIN%|$XREMAP_BIN|g" \
        -e "s|%XREMAP_CONFIG%|$XREMAP_CONFIG|g" \
        -e "s|%XREMAP_DEVICE_FLAG%|$XREMAP_DEVICE_FLAG|g" \
        "$SCRIPT_DIR/xremap.service" > "$SYSTEMD_USER_DIR/xremap.service"
    
    echo "✓ Xremap service file generated"
    echo ""
fi

# Reload systemd
echo "Reloading systemd..."
systemctl --user daemon-reload
echo "✓ Systemd reloaded"
echo ""

# Enable and start services
if [ "$INSTALL_FLATPAK" = true ]; then
    echo "Enabling flatpak service..."
    systemctl --user enable flatpak-autoupdate.timer
    systemctl --user start flatpak-autoupdate.timer
    echo "✓ Flatpak service started"
    echo ""
fi

if [ "$INSTALL_XREMAP" = true ]; then
    echo "Enabling xremap service..."
    systemctl --user enable xremap.service
    systemctl --user restart xremap.service
    echo "✓ Xremap service started"
    echo ""
fi

# Show status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation complete! Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$INSTALL_FLATPAK" = true ]; then
    echo "Flatpak Auto-Update:"
    systemctl --user list-timers flatpak-autoupdate.timer --no-pager
    echo ""
fi

if [ "$INSTALL_XREMAP" = true ]; then
    echo "Xremap:"
    systemctl --user status xremap.service --no-pager | head -10
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation complete!"
echo ""

if [ "$INSTALL_FLATPAK" = true ]; then
    echo "Flatpak auto-update service:"
    echo "  • Runs automatically $LOGIN_DELAY after login"
    echo "  • Updates flatpak packages only once per day"
    echo "  • Desktop notifications on completion/failure"
    echo "  • View logs: journalctl --user -u flatpak-autoupdate.service"
    echo ""
fi

if [ "$INSTALL_XREMAP" = true ]; then
    echo "Xremap service:"
    echo "  • Running continuously in background"
    echo "  • Remaps keyboard and mouse buttons"
    echo "  • Monitoring devices: ${XREMAP_DEVICES:-"(all devices)"}"
    echo ""
fi

echo "Configuration: $SCRIPT_DIR/config.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
