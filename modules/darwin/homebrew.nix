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
      "alexsjones/llmfit"
      "anomalyco/tap"
      "arimxyer/tap"
      "charmbracelet/tap"
      "FelixKratz/formulae"
      "gromgit/brewtils"
      "homebrew/autoupdate"
      "jakehilborn/jakehilborn"
      "nguyenphutrong/tap"
      "nikitabobko/tap"
      "oven-sh/bun"
      "ovh/tap"
      "protonpass/tap"
      "rjyo/moshi"
      "steipete/tap"
      "vishvavariya/notchy"
    ];

    brews = [
      # Tap formulae (not in nixpkgs)
      "felixkratz/formulae/borders"
      "alexsjones/llmfit/llmfit"
      "rjyo/moshi/moshi-hook"
      "agavra/tap/tuicr"
      "arimxyer/tap/models"
      "gromgit/brewtils/taproom"
      "modem-dev/tap/hunk"
      "protonpass/tap/pass-cli"
      "worktrunk"
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
      "cmux"
      "codexbar"
      "font-fira-code"
      "font-fira-code-nerd-font"
      "font-iosevka"
      "font-jetbrains-mono-nerd-font"
      "font-meslo-for-powerlevel10k"
      "ghostty"
      "google-chrome"
      "home-assistant"
      "lulu"
      "nguyenphutrong/tap/quotio"
      "nikitabobko/tap/aerospace"
      "obsidian"
      "orbstack"
      "ovh/tap/ovhcloud-cli"
      "proton-pass"
      "protonvpn"
      "raycast"
      "tableplus"
      "vishvavariya/notchy/notchy"
      "visual-studio-code"
      "wezterm"
      "zed"
      "zen"
    ];

    masApps = {
      "Irvue" = 1039633667;
      "Tailscale" = 1475387142;
      "WireGuard" = 1451685025;
    };
  };
}
