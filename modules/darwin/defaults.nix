{ ... }:

{
  # macOS preferences ported from scripts/mac.sh (phase 3).
  # scripts/mac.sh remains the classic-path authority for the same
  # settings; keep values in sync until the classic path is retired.
  # Deliberately not ported (stay imperative in mac.sh): folder
  # creation, chflags on ~/Library, the Spotlight hotkey PlistBuddy
  # edit (CustomUserPreferences would clobber the whole
  # AppleSymbolicHotKeys dict), pmset, nvram, media-key launchctl,
  # displayplacer, screensaver password, and system updates.
  system.defaults = {
    NSGlobalDomain = {
      # Appearance
      AppleInterfaceStyle = "Dark";
      # Finder / files
      AppleShowAllExtensions = true;
      # Trackpad / scrolling
      "com.apple.swipescrolldirection" = false;
      # Keyboard
      AppleKeyboardUIMode = 3;
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      # Menu bar / scrollbars
      _HIHideMenuBar = true;
      AppleShowScrollBars = "Always";
      # Dialogs
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      # Display
      AppleFontSmoothing = 2;
    };

    finder = {
      FXDefaultSearchScope = "SCcf";
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      CreateDesktop = false;
    };

    dock = {
      tilesize = 48;
      mineffect = "scale";
      minimize-to-application = true;
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      static-only = true;
      show-recents = false;
      mru-spaces = false;
    };

    spaces.spans-displays = true;

    trackpad.Clicking = true;

    screencapture = {
      location = "~/Screenshots";
      show-thumbnail = false;
    };

    LaunchServices.LSQuarantine = false;

    ActivityMonitor = {
      # "All Processes"; mac.sh writes legacy value 0 for the same view
      ShowCategory = 100;
      IconType = 5;
    };

    CustomUserPreferences = {
      # Liquid glass tinted (no native nix-darwin option yet)
      NSGlobalDomain.AppleGlassStyle = 1;
      "com.apple.menuextra.clock".DateFormat = "EEE MMM d  H.mm";
      "com.apple.menuextra.battery" = {
        ShowPercent = "YES";
        ShowTime = "NO";
      };
      "com.apple.TextEdit" = {
        RichText = 0;
        PlainTextEncoding = 4;
      };
    };
  };
}
