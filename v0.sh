#!/bin/zsh

# Shell script to debloat macOS on M1 Pro, keeping essential services online
# Run with sudo, e.g., `sudo ./debloat_m1pro.sh`
# USE AT YOUR OWN RISK

echo "Starting macOS debloat for M1 Pro..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use sudo."
   exit 1
fi

# List of non-essential services to disable (carefully chosen to avoid breaking core functionality)
NON_ESSENTIAL_SERVICES=(
    "com.apple.siri"                   # Siri
    "com.apple.analyticsd"             # Analytics daemon
    "com.apple.Spotlight"             # Spotlight indexing
    "com.apple.GameController.gamecontrollerd"  # Game controller service
    "com.apple.photoanalysisd"         # Photos analysis
    "com.apple.CloudPhotosConfiguration"  # iCloud Photos
    "com.apple.Maps.mapspushd"        # Maps push notifications
    "com.apple.newsd"                 # Apple News daemon
    "com.apple.remindd"               # Reminders
    "com.apple.touristd"              # Location-based suggestions
    "com.apple.podcasts"              # Podcasts
)

# Disable non-essential services
for SERVICE in "${NON_ESSENTIAL_SERVICES[@]}"; do
    echo "Disabling $SERVICE..."
    launchctl disable "gui/$UID/$SERVICE" 2>/dev/null
    launchctl bootout "gui/$UID/$SERVICE" 2>/dev/null
    if launchctl list | grep -q "$SERVICE"; then
        echo "Warning: $SERVICE still running or failed to disable."
    else
        echo "$SERVICE disabled successfully."
    fi
done

# Disable Spotlight indexing entirely (optional, comment out if you want Spotlight)
echo "Disabling Spotlight indexing..."
sudo mdutil -a -i off

# Disable analytics and diagnostic reporting
echo "Disabling analytics and diagnostics..."
defaults write com.apple.crashreporter DialogType none
defaults write com.apple.analytics AnalyticsEnabled -bool false

# Remove non-essential apps from Dock (optional)
echo "Cleaning up Dock..."
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
killall Dock

# Disable Device Enrollment Notifications (MDM pop-ups)
echo "Disabling MDM enrollment notifications..."
sudo rm -f /var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
sudo rm -f /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
sudo touch /var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
sudo touch /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound

# Clear caches for some non-essential services
echo "Clearing caches..."
sudo rm -rf ~/Library/Caches/com.apple.Siri*
sudo rm -rf ~/Library/Caches/com.apple.analytics*
sudo rm -rf ~/Library/Caches/com.apple.Spotlight*

# Ensure essential services are left untouched
echo "Verifying essential services..."
ESSENTIAL_SERVICES=(
    "com.apple.mDNSResponder"      # Networking (Bonjour)
    "com.apple.coreaudio"          # Audio
    "com.apple.systemuiserver"     # System UI
    "com.apple.kernelmanagerd"     # Kernel management
    "com.apple.notifyd"            # Notifications
)
for SERVICE in "${ESSENTIAL_SERVICES[@]}"; do
    if launchctl list | grep -q "$SERVICE"; then
        echo "$SERVICE is running (essential, not touched)."
    else
        echo "Warning: $SERVICE not running, may require manual check."
    fi
done

echo "Debloating complete. Reboot recommended."
echo "Check system stability and re-enable services if needed."
