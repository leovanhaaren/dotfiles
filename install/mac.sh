#!/bin/bash

echo "# Setting global mac configs from mac.sh"

# Close any open System Preferences panes, to prevent them from overriding
# settings we're about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

##################
### Appearance ###
##################

# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Liquid glass tinted
defaults write NSGlobalDomain AppleGlassStyle -int 1

###############
### Folders ###
###############

echo "# Creating folders"
mkdir -p ~/Workspaces/leovanhaaren/dotfiles
mkdir -p ~/Screenshots

##############
### Finder ###
##############

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show the ~/Library folder
chflags nohidden ~/Library

# Use current directory as default search scope
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Show Path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show Status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Sort folders first when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Disable extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Hide all desktop icons
defaults write com.apple.finder CreateDesktop -bool false

############
### Dock ###
############

# Set icon size
defaults write com.apple.dock tilesize -int 48

# Use scale effect for minimize animation
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows to application icon
defaults write com.apple.dock minimize-to-application -bool true

# Auto hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Speed up dock show/hide
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -int 0

# Only show active apps in dock
defaults write com.apple.dock static-only -bool true

# Hide 'recent applications' from dock
defaults write com.apple.dock show-recents -bool false

# Don't rearrange spaces based on recent use
defaults write com.apple.dock mru-spaces -bool false

################
### Trackpad ###
################

# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Disable natural scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

################
### Keyboard ###
################

# Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1

# Set a shorter delay until key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable double-space period
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable CMD+space for spotlight
/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c "Set AppleSymbolicHotKeys:64:enabled false"

################
### Menu Bar ###
################

# Show remaining battery percentage
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write com.apple.menuextra.battery ShowTime -string "NO"

# Set date display format
defaults write com.apple.menuextra.clock "DateFormat" "EEE MMM d  H.mm"

# Automatically hide and show the menu bar on desktop only
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Always show scrollbars
defaults write -g AppleShowScrollBars -string "Always"

###################
### Screenshots ###
###################

# Remove delay when taking a screenshot
defaults write com.apple.screencapture show-thumbnail -bool false

# Store screenshots in ~/Screenshots
defaults write com.apple.screencapture location ~/Screenshots

###############
### Dialogs ###
###############

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

##############
### Safari ###
##############

# # Show full URL in search field
# sudo defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# # Enable Develop menu
# sudo defaults write com.apple.Safari IncludeDevelopMenu -bool true

# # Don't auto-open safe downloads
# sudo defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

########################
### Activity Monitor ###
########################

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Show CPU usage in dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

################
### TextEdit ###
################

# Default to plain text
defaults write com.apple.TextEdit RichText -int 0

# Open files as UTF-8
defaults write com.apple.TextEdit PlainTextEncoding -int 4

###############
### Display ###
###############

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 2

# Set display resolution to 3008x1692
sudo displayplacer "res:3008x1692"

# Turn display off when inactive for 1 hour (60 minutes)
sudo pmset -a displaysleep 60

#############
### Media ###
#############

# Stop iTunes from responding to the keyboard media keys
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

################
### Security ###
################

# Require password after screensaver never
defaults write com.apple.screensaver askForPassword -int 0

##############
### System ###
##############

# Prevent automatic sleeping when display is off
sudo pmset -a sleep 0

# Start up automatically after a power failure
sudo pmset -a autorestart 1

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Update Apple developer utils
softwareupdate --all --install --force

################
### Restart  ###
################

killall Dock
killall SystemUIServer
