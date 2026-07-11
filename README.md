# Dotfiles

Personal dotfiles for macOS and Linux development environments.

## Installation

### Prerequisites

- Git
- Bash (for running the setup scripts)

### 1. Clone the Repository

```bash
git clone git@github.com:leovanhaaren/dotfiles.git ~/Workspaces/leovanhaaren/dotfiles
cd ~/Workspaces/leovanhaaren/dotfiles
```

### 2. Create Symlinks via GNU Stow

```bash
./setup.sh
```

This detects the OS and creates the appropriate symlinks for shell config, git, SSH, editor settings, and custom scripts. Use `./setup.sh -n` for a dry run to preview changes.

### 3. Install Packages

#### macOS

```bash
# Install Homebrew packages
./scripts/brew.sh                    # defaults to Brewfile.base
./scripts/brew.sh homebrew/Brewfile.work   # add work-specific packages

# Apply macOS preferences
./scripts/mac.sh
./scripts/mac.sh --apply-display --disable-screensaver-password  # optional personal settings
```

#### Ubuntu Server

```bash
# Install packages, Oh My Zsh, NVM, Bun, pnpm, Go, and set zsh as default shell
./scripts/ubuntu.sh
```

(Note: the Ubuntu bootstrap script exists on the `my-new-feature` branch and needs to be ported to `main`. See `scripts/install.sh` as a starting point.)

### 4. Verify

```bash
./verify.sh
```

## What's Included

### Shell Configuration
- **.zshrc** — Zsh configuration with Oh My Zsh (stowed to `~/`)
- **.zprofile** — Environment variables and PATH setup (stowed to `~/`)
- **.aliases** — Shell aliases (stowed to `~/`)
- **.functions** — Shell functions (commit, acp, git worktrees, etc.) (stowed to `~/`)
- **.config/fish/** — Fish shell configuration (stowed to `~/.config/fish/`)

### Git
- **.gitconfig** — Git configuration with SSH signing via 1Password (stowed to `~/`)
- **.config/git/ksyos.gitconfig** — Conditional config for work account (stowed to `~/.config/git/`)
- **.config/git/hooks/** — Git hooks for automation (stowed to `~/.config/git/`)

### Applications
- **homebrew/Brewfile.base** — Primary Homebrew package set
- **homebrew/Brewfile.work** — Work-specific packages (1Password, AWS, etc.)
- **vscode/settings.json** — VS Code editor settings (symlinked manually on each OS)
- **vscode/extensions.list** — Documented VS Code extensions (not auto-installed)

### Terminal Emulators
- **.tmux.conf** — Tmux configuration with TPM, Catppuccin theme, resurrect, floax (stowed to `~/`)
- **.gitmux.conf** — Git status in tmux status bar (stowed to `~/`)
- **.config/wezterm/wezterm.lua** — Wezterm configuration (stowed to `~/.config/wezterm/`)
- **.config/ghostty/config** — Ghostty terminal configuration (stowed to `~/.config/ghostty/`)

### Window Management
- **.config/aerospace/aerospace.toml** — AeroSpace window manager configuration (stowed to `~/.config/aerospace/`)
  - Do not also create `~/.aerospace.toml`; AeroSpace errors when both config locations exist.

### Session Management
- **.config/sesh/sesh.toml** - Sesh session manager configuration (stowed to `~/.config/sesh/`)
- **.config/television/** - Television fuzzy finder and agent session channels (stowed to `~/.config/television/`)
- **bin/agent-sessions** - Lists, previews, and resumes local Claude, Codex, OpenCode, and Pi sessions
- **.config/worktrunk/config.toml** - Worktrunk git worktree manager (stowed to `~/.config/worktrunk/`)

### Other Tools
- **.config/starship.toml** — Starship prompt configuration (stowed to `~/.config/`)
- **.config/mise/config.toml** — Mise version manager config (stowed to `~/.config/mise/`)
- **.config/zed/settings.json** — Zed editor settings (stowed to `~/.config/zed/`)

## Directory Structure

```
dotfiles/
├── setup.sh              # Main installer (creates symlinks via GNU Stow)
├── uninstall.sh          # Remove symlinks
├── verify.sh             # Verify installation
├── .stow-local-ignore    # Stow exclusion patterns
│
├── .zshrc                # Shell: Zsh configuration (stowed to ~/)
├── .zprofile             # Shell: Environment setup (stowed to ~/)
├── .aliases              # Shell: Aliases (stowed to ~/)
├── .functions            # Shell: Custom functions (stowed to ~/)
├── .config/              # Shell: XDG config
│   └── fish/             #   Fish shell config
│
├── .gitconfig            # Git: Main config (stowed to ~/)
├── .config/git/          # Git: Ignore, hooks, work config (stowed to ~/.config/git/)
│
├── .tmux.conf            # Tmux: Main config (stowed to ~/)
├── .gitmux.conf          # Tmux: Git status (stowed to ~/)
├── .config/sesh/         # Tmux: Sesh session config (stowed to ~/.config/sesh/)
├── .config/television/   # Tmux: Television config (stowed to ~/.config/television/)
├── bin/                  # Commands stowed to ~/bin/
│   └── agent-sessions    #   Browse and resume coding-agent sessions
│
├── .config/wezterm/      # Terminal: Wezterm config (stowed to ~/.config/wezterm/)
├── .config/ghostty/      # Terminal: Ghostty config (stowed to ~/.config/ghostty/)
│
├── .config/aerospace/    # Window manager: AeroSpace config (stowed to ~/.config/aerospace/)
│
├── .config/starship.toml # Prompt: Starship (stowed to ~/.config/)
├── .config/mise/         # Tools: Mise version manager (stowed to ~/.config/mise/)
├── .config/zed/          # Editor: Zed settings (stowed to ~/.config/zed/)
├── .config/worktrunk/    # Tools: Worktrunk (stowed to ~/.config/worktrunk/)
│
├── homebrew/             # Homebrew package lists (not stowed)
│   ├── Brewfile.base     #   Primary package set
│   └── Brewfile.work     #   Work-specific packages
│
├── ssh/                  # SSH configuration (not stowed, linked by setup.sh)
│   ├── config.macos      #   macOS SSH config
│   └── config.linux      #   Linux SSH config
│
├── vscode/               # VS Code settings (not stowed, linked by setup.sh)
│   ├── settings.json
│   └── extensions.list
│
├── scripts/              # Setup/utility scripts (not stowed)
│   ├── brew.sh           #   Homebrew installation
│   ├── mac.sh            #   macOS preferences
│   ├── install.sh        #   Meta-installer (calls brew.sh)
│   ├── homebrew-ssd.sh   #   Move Homebrew to external SSD
│   └── ssh-load-keys.sh  #   Load SSH keys from Proton Pass
│
└── .gitignore            # Git ignore rules (git only, not stowed)
```

## Aliases Reference

### Navigation
| Alias | Description |
|-------|-------------|
| `w` | Navigate to ~/Workspaces |
| `reload` | Reload zsh configuration |
| `h` | Launch herdr |

### Symlinks
| Alias | Description |
|-------|-------------|
| `symlinkls` | List symlinks in current directory |
| `symlinkrm` | Remove symlinks in current directory |

### Git Worktrees
| Alias | Description |
|-------|-------------|
| `gwl` | List worktrees |
| `gwa` | Add worktree |
| `gwr` | Remove worktree |
| `gwp` | Prune worktrees |
| `gwab <branch>` | Create new branch worktree |
| `gwae <branch>` | Add existing branch worktree |
| `gwao <branch>` | Add worktree tracking origin branch |
| `gwcd <name>` | Navigate to worktree by name |

### Claude Code
| Alias | Description |
|-------|-------------|
| `zai` | Run Claude with z.ai config |
| `mm` | Run Claude with minimax config |
| `ccc` | Run Claude in container |

### Tmux
| Alias | Description |
|-------|-------------|
| `s` | Launch sesh session picker |
| `ais` | Launch agent session picker |
| `ta` | Attach to tmux session |
| `tad` | Attach (detaching others) |
| `tl` | List tmux sessions |
| `tn` | New tmux session |
| `tna` | New or attach session |
| `tk` | Kill tmux session |
| `tks` | Kill tmux server |
| `trw` | Rename tmux window |

### Agent Session Picker

Run `tv agent-sessions`, or press prefix then `A` in tmux, to browse sessions from all four coding harnesses.

| Harness | Resume command |
|---------|----------------|
| Claude | `claude --resume <id>` |
| Codex | `codex resume <id> -C <cwd>` |
| OpenCode | `opencode --session <id>` |
| Pi | `pi --session <file>` |

The picker reads Claude, Codex, and Pi session metadata from their JSONL stores.
It obtains OpenCode sessions through `opencode session list`, grouped by projects reported by `opencode debug scrap`.
Session previews stay local and show only the selected transcript.

### Decisions

- Agent conversations use a separate Television channel instead of overloading Sesh's connect action.
- Picker selections carry an opaque encoded record so session titles cannot alter shell commands.
- Resume defaults to a dry run in `agent-sessions`; the Television action passes `--apply` explicitly.
- Missing or malformed session files are skipped so one dirty history cannot break the picker.

## Custom Functions

### AI-Assisted Commits
```bash
commit        # Stage? No. Generate message from staged diff, confirm, commit
acp           # Stage all, generate message, commit, push
```

Both use `claude -p --model haiku` to generate commit messages in Conventional Commits format.

### Git Worktrees
```bash
gwab <branch>   # Create new branch worktree
gwae <branch>   # Add existing branch worktree
gwao <branch>   # Add worktree tracking origin branch
gwcd <name>     # Navigate to worktree by name
```

### Port Management
```bash
check-port 3000    # Check if port is in use
kill-port 3000     # Kill process on port
```
(Requires `bin/` directory — currently on `my-new-feature` branch, pending merge.)

## Local Overrides

Files ending in `.local` are sourced but not tracked in git:
- `~/.aliases.local` — Local alias overrides
- `~/.zshrc.local` — Local zsh configuration
- `~/.tmux.conf.local` — Local tmux configuration

## Homebrew

Brewfiles are stored under `homebrew/`:
- **Brewfile.base** — Primary package set for the main machine
- **Brewfile.work** — Work-specific packages (1Password, AWS CLI, etc.)

### Sync system with Brewfile
```bash
# Check what's missing (dry run)
brew bundle check --file=homebrew/Brewfile.base

# Install missing packages
brew bundle --file=homebrew/Brewfile.base

# See what would be installed
brew bundle list --file=homebrew/Brewfile.base

# Add work packages as well
brew bundle --file=homebrew/Brewfile.work
```

### Update Brewfiles from system (preserving comments)
The `brew-update.sh` script is available on the `my-new-feature` branch but not yet on `main`. For now, update manually.

### Cleanup unused packages
```bash
brew bundle cleanup --force --file=homebrew/Brewfile.base
```

## Verification

Run installation checks and the agent-session tests:

```bash
./verify.sh
bun test scripts/tests/agent-sessions.test.ts
agent-sessions list | head
```

`tv list-channels` should include `agent-sessions` after setup.

## Troubleshooting

### Symlinks not working
```bash
# Remove existing symlinks
./uninstall.sh

# Recreate symlinks
./setup.sh
```

### Permission denied on scripts
```bash
chmod +x setup.sh uninstall.sh verify.sh
chmod +x scripts/*
```

### 1Password SSH signing not working
```bash
# Set local SSH program for specific repo
git config --local gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
```

## Credits

Inspired by:
- [anhari.dev - Saving VSCode settings in your dotfiles](https://anhari.dev/blog/saving-vscode-settings-in-your-dotfiles)
