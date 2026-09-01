{ ... }:

{
  # Everything that stays on Homebrew: casks, Mac App Store apps, and
  # formulae from third-party taps or with macOS-specific daemons.
  # Formulae available in nixpkgs live in modules/home/default.nix.
  homebrew = {
    enable = true;
    # Phase 1 safety: never uninstall anything not listed here.
    # Tighten to "zap" once the Brewfiles are retired.
    onActivation.cleanup = "none";

    taps = [
      "anomalyco/tap"
      "charmbracelet/tap"
      "FelixKratz/formulae"
      # "homebrew/autoupdate"
      "jakehilborn/jakehilborn"
      "nguyenphutrong/tap"
      "nikitabobko/tap"
      # "ovh/tap"
      "protonpass/tap"
      "rjyo/moshi"
      "steipete/tap"
      "vishvavariya/notchy"
    ];

    brews = [
      # Mac App Store apps disabled for now; re-enable mas and the
      # masApps block below together (brew bundle shells out to mas,
      # so mas must come from Homebrew, not nix).
      # "mas"
      # Tap formulae (not in nixpkgs). nix-darwin emits `trusted: true`
      # for fully-qualified entries by default, matching the per-entry
      # trust the classic Brewfiles declare explicitly.
      "felixkratz/formulae/borders"
      "rjyo/moshi/moshi-hook"
      "protonpass/tap/pass-cli"
      "worktrunk"
      "hunk"
      "llmfit"
      "taproom"
      "tuicr"
      "models"
      "mole"
      "railway"
      "bruno-cli"
      "homeassistant-cli"
      # macOS daemon / system integration
      "tailscale"
      # Libraries pulled in explicitly by the old Brewfile
      "aom"
      "glib"
      "libheif"
      "webp"
      # Shell stack stays on brew until Phase 2 migrates zsh
      "zsh"
      "zsh-autosuggestions"
      "zsh-syntax-highlighting"
    ];

    casks = [
      "bruno"
      "codexbar"
      # Fonts live in fonts.packages (modules/darwin/default.nix);
      # cleanup = "none" leaves the brew-installed copies alone.
      "ghostty"
      "google-chrome"
      "home-assistant"
      "lulu"
      "nguyenphutrong/tap/quotio"
      "nikitabobko/tap/aerospace"
      "obsidian"
      "orbstack"
      # "ovh/tap/ovhcloud-cli"
      "proton-pass"
      "protonvpn"
      "raycast"
      "sloth"
      "tableplus"
      "vishvavariya/notchy/notchy"
      "visual-studio-code"
      "wezterm"
      "zed"
      "zen"
    ];

    # masApps = {
    #   "Irvue" = 1039633667;
    #   "Tailscale" = 1475387142;
    #   "WireGuard" = 1451685025;
    # };
  };
}
