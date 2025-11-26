# User Systemd Services

Collection of systemd user services for automatic tasks and utilities.

## Services

### 1. Flatpak Auto-Update
Automatically update Flatpak packages once per day after login.

**Features:**
- **Once-per-day updates**: Checks timestamp to ensure flatpak only updates once daily
- **Login-triggered**: Runs automatically after you log in (with configurable delay)
- **Desktop notifications**: Get notified when updates complete or fail
- **Automatic logging**: All updates logged for your records
- **Non-intrusive**: Configurable delay after login to avoid system load at startup

### 2. Xremap
Keyboard and mouse button remapper running as a persistent service.

**Features:**
- **Persistent service**: Runs continuously in the background
- **Auto-restart**: Automatically restarts if it crashes
- **Custom key mappings**: Remap keyboard shortcuts and mouse buttons
- **Application-specific**: Different mappings for different applications
- **Device filtering**: Target specific keyboards/mice

## Installation

1. **Copy the configuration template:**
   ```bash
   cp config.sh.example config.sh
   ```

2. **Edit `config.sh` to match your preferences:**
   ```bash
   nano config.sh
   ```
   
   **Flatpak Auto-Update settings:**
   - `LOG_DIR`: Where to store update logs and timestamp file (defaults to project directory)
   - `LOGIN_DELAY`: How long to wait after login before attempting update
   
   **Xremap settings:**
   - `XREMAP_BIN`: Path to xremap binary
   - `XREMAP_CONFIG`: Path to xremap configuration file
   - `XREMAP_DEVICES`: Devices to monitor (comma-separated)

3. **Ensure xremap config exists (if using xremap):**
   ```bash
   # Make sure you have xremap config at ~/.config/xremap/config.yml
   # Or update XREMAP_CONFIG path in config.sh
   ```

4. **Run the installation script:**
   ```bash
   chmod +x install.sh
   
   # Install both services (default)
   ./install.sh
   
   # Or install only flatpak auto-update
   ./install.sh --flatpak-only
   
   # Or install only xremap
   ./install.sh --xremap-only
   ```

5. **That's it!** Services will run automatically.

## Usage

### Flatpak Auto-Update Commands

```bash
# Check timer status
systemctl --user status flatpak-autoupdate.timer

# Check when next update is scheduled
systemctl --user list-timers flatpak-autoupdate.timer

# View update logs (in the project directory)
cat update.log

# Check when last update ran
cat last-update

# Manually run update (will respect once-per-day limit)
./flatpak-update-daily.sh

# Force immediate update (bypasses once-per-day check)
flatpak update -y

# Restart timer
systemctl --user restart flatpak-autoupdate.timer

# Stop/disable timer
systemctl --user stop flatpak-autoupdate.timer
systemctl --user disable flatpak-autoupdate.timer
```

### Xremap Commands

```bash
# Check service status
systemctl --user status xremap.service

# View logs
journalctl --user -u xremap.service -f

# Restart service (e.g., after config change)
systemctl --user restart xremap.service

# Stop/disable service
systemctl --user stop xremap.service
systemctl --user disable xremap.service

# Test xremap configuration
xremap ~/.config/xremap/config.yml --device=YourDevice
```

## How It Works

1. When you log in, `flatpak-autoupdate.timer` triggers after the configured delay (default: 1 minute)
2. The timer activates `flatpak-autoupdate.service`, which runs `flatpak-update-daily.sh`
3. The script checks if flatpak has already been updated today (by reading timestamp file)
4. If not updated today, it runs `flatpak update -y` and saves today's date
5. You get a desktop notification when the update completes or fails
6. All activity is logged to `update.log` in the project directory

## Configuration Files

**Common:**
- `config.sh.example` - Template configuration file
- `config.sh` - Your local configuration (git-ignored)
- `install.sh` - Installation script for all services

**Flatpak Auto-Update:**
- `flatpak-autoupdate.service` - Systemd service template
- `flatpak-autoupdate.timer` - Systemd timer template (triggers on login)
- `flatpak-update-daily.sh` - Update script with once-per-day logic

**Xremap:**
- `xremap.service` - Systemd service template
- (Config managed separately at path specified in `config.sh`)

## Troubleshooting

### Update not running?
Check timer status:
```bash
systemctl --user status flatpak-autoupdate.timer
journalctl --user -u flatpak-autoupdate.service
```

### Already updated today message?
The script prevents multiple updates per day. To force an update:
```bash
rm last-update
./flatpak-update-daily.sh
```

### No notifications?
Make sure you have either `notify-send` or `kdialog` installed:
```bash
# For GNOME/generic
sudo dnf install libnotify

# For KDE (usually pre-installed)
sudo dnf install kde-cli-tools
```

### View detailed logs
```bash
cat update.log
```

## Customization

### Change update delay
Edit `config.sh` and change `LOGIN_DELAY`:
```bash
LOGIN_DELAY="5min"  # Wait 5 minutes after login
```

Then reinstall:
```bash
./install.sh
```

### Change log location
Edit `config.sh` and change `LOG_DIR` to a different path:
```bash
LOG_DIR="/path/to/custom/logs"
```

## Uninstallation

### Remove Flatpak Auto-Update
```bash
systemctl --user stop flatpak-autoupdate.timer
systemctl --user disable flatpak-autoupdate.timer
rm ~/.config/systemd/user/flatpak-autoupdate.{service,timer}
systemctl --user daemon-reload

# Optionally remove logs
rm update.log last-update
```

### Remove Xremap
```bash
systemctl --user stop xremap.service
systemctl --user disable xremap.service
rm ~/.config/systemd/user/xremap.service
systemctl --user daemon-reload
```

## Why This Approach?

- **User services**: Runs as your user, no need for sudo/system modifications
- **Systemd integration**: Reliable, standard Linux service management
- **Configurable**: Easy to customize paths and settings
- **Portable**: Easy to move between systems
- **Template-based**: Uses sed to generate service files from templates

## Notes

### Flatpak Auto-Update
- Flatpak updates require no password (user-level flatpaks)
- If you have system-level flatpaks, they won't be updated (require root)
- The update runs in the background; you can continue working immediately after login
- Lingering is not required since this triggers on login (not a persistent service)

### Xremap
- Requires xremap to be installed (`cargo install xremap --features x11`)
- Configure devices in `config.sh` - use `\s` for spaces in device names
- Xremap config uses YAML format - see example for syntax
- The service automatically restarts on failure

