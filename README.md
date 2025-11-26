# Flatpak Auto-Update

Systemd user service to automatically update Flatpak packages once per day after login.

## Features

- **Once-per-day updates**: Checks timestamp to ensure flatpak only updates once daily
- **Login-triggered**: Runs automatically after you log in (with configurable delay)
- **Desktop notifications**: Get notified when updates complete or fail
- **Automatic logging**: All updates logged for your records
- **Non-intrusive**: Configurable delay after login to avoid system load at startup

## Installation

1. **Copy the configuration template:**
   ```bash
   cp config.sh.example config.sh
   ```

2. **Edit `config.sh` to match your preferences (optional):**
   ```bash
   nano config.sh
   ```
   
   Customize these variables:
   - `LOG_DIR`: Where to store update logs and timestamp file (defaults to project directory)
   - `LOGIN_DELAY`: How long to wait after login before attempting update

3. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

4. **That's it!** The service will run automatically on your next login.

## Usage

```bash
# Check timer status
systemctl --user status flatpak-autoupdate.timer

# Check when next update is scheduled
systemctl --user list-timers flatpak-autoupdate.timer

# View update logs (in the project directory)
cat /home/nitro5/Projects/autostart-login/update.log

# Check when last update ran
cat /home/nitro5/Projects/autostart-login/last-update

# Manually run update (will respect once-per-day limit)
./flatpak-update-daily.sh

# Force immediate update (bypasses once-per-day check)
flatpak update -y

# Restart timer
systemctl --user restart flatpak-autoupdate.timer

# Stop timer
systemctl --user stop flatpak-autoupdate.timer

# Disable timer
systemctl --user disable flatpak-autoupdate.timer
```

## How It Works

1. When you log in, `flatpak-autoupdate.timer` triggers after the configured delay (default: 1 minute)
2. The timer activates `flatpak-autoupdate.service`, which runs `flatpak-update-daily.sh`
3. The script checks if flatpak has already been updated today (by reading timestamp file)
4. If not updated today, it runs `flatpak update -y` and saves today's date
5. You get a desktop notification when the update completes or fails
6. All activity is logged to `update.log` in the project directory

## Configuration Files

- `config.sh.example` - Template configuration file
- `config.sh` - Your local configuration (git-ignored)
- `flatpak-autoupdate.service` - Systemd service template
- `flatpak-autoupdate.timer` - Systemd timer template (triggers on login)
- `flatpak-update-daily.sh` - Update script with once-per-day logic
- `install.sh` - Installation script

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
rm /home/nitro5/Projects/autostart-login/last-update
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
cat /home/nitro5/Projects/autostart-login/update.log
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

```bash
systemctl --user stop flatpak-autoupdate.timer
systemctl --user disable flatpak-autoupdate.timer
rm ~/.config/systemd/user/flatpak-autoupdate.{service,timer}
systemctl --user daemon-reload
```

Optionally remove logs (from project directory):
```bash
rm /home/nitro5/Projects/autostart-login/{update.log,last-update}
```

## Why This Approach?

- **User service**: Runs as your user, no need for sudo/system modifications
- **Login-triggered**: Ensures updates happen when you're actually using the system
- **Once daily**: Prevents excessive updates while keeping packages current
- **Non-blocking**: Uses systemd timer so it doesn't slow down your login
- **Portable**: Easy to customize and move between systems

## Notes

- Flatpak updates require no password (user-level flatpaks)
- If you have system-level flatpaks, they won't be updated (require root)
- The update runs in the background; you can continue working immediately after login
- Lingering is not required since this triggers on login (not a persistent service)

