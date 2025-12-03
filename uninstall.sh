#!/bin/bash
#
# Uninstall User Systemd Services
# Run this script to remove the services
#

set -e

# Parse command line arguments
UNINSTALL_FLATPAK=true
UNINSTALL_XREMAP=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --flatpak-only)
            UNINSTALL_XREMAP=false
            shift
            ;;
        --xremap-only)
            UNINSTALL_FLATPAK=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--flatpak-only | --xremap-only]"
            exit 1
            ;;
    esac
done

# Systemd user directory
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

echo ""
echo "Uninstalling User Systemd Services..."
echo ""

# ========================================
# Uninstall Flatpak Auto-Update Service
# ========================================
if [ "$UNINSTALL_FLATPAK" = true ]; then
    echo "━━━ Flatpak Auto-Update ━━━"
    
    if systemctl --user is-active flatpak-autoupdate.timer &>/dev/null; then
        echo "Stopping flatpak timer..."
        systemctl --user stop flatpak-autoupdate.timer
    fi
    
    if systemctl --user is-enabled flatpak-autoupdate.timer &>/dev/null; then
        echo "Disabling flatpak timer..."
        systemctl --user disable flatpak-autoupdate.timer
    fi
    
    echo "Removing flatpak service files..."
    rm -f "$SYSTEMD_USER_DIR/flatpak-autoupdate.service"
    rm -f "$SYSTEMD_USER_DIR/flatpak-autoupdate.timer"
    
    echo "✓ Flatpak auto-update removed"
    echo ""
    
    # Ask about state directory
    if [ -d "$HOME/.local/share/flatpak-autoupdate" ]; then
        echo "Remove state directory (~/.local/share/flatpak-autoupdate)? [y/N]"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.local/share/flatpak-autoupdate"
            echo "✓ State directory removed"
        else
            echo "State directory kept"
        fi
        echo ""
    fi
fi

# ========================================
# Uninstall Xremap Service
# ========================================
if [ "$UNINSTALL_XREMAP" = true ]; then
    echo "━━━ Xremap ━━━"
    
    if systemctl --user is-active xremap.service &>/dev/null; then
        echo "Stopping xremap service..."
        systemctl --user stop xremap.service
    fi
    
    if systemctl --user is-enabled xremap.service &>/dev/null; then
        echo "Disabling xremap service..."
        systemctl --user disable xremap.service
    fi
    
    echo "Removing xremap service file..."
    rm -f "$SYSTEMD_USER_DIR/xremap.service"
    
    echo "✓ Xremap removed"
    echo ""
fi

# Reload systemd
echo "Reloading systemd..."
systemctl --user daemon-reload
echo "✓ Systemd reloaded"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Uninstallation complete!"
echo ""
echo "Note: The project files in this directory were NOT removed."
echo "To reinstall later, run: ./install.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

