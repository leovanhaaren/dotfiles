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

### 2. Create Symlinks

```bash
./setup.sh
```

This detects the OS and creates the appropriate symlinks for shell config, git, SSH, editor settings, and custom scripts. Use `./setup.sh -n` for a dry run to preview changes.

### 3. Install Packages

#### macOS

```bash
# Install Homebrew packages
./install/brew.sh                    # defaults to Brewfile.installed
./install/brew.sh Brewfile.slim      # smaller machine profile

# Apply macOS preferences
./install/mac.sh
./install/mac.sh --apply-display --disable-screensaver-password  # optional personal settings
```

#### Ubuntu Server

```bash
# Install packages, Oh My Zsh, NVM, Bun, pnpm, Go, and set zsh as default shell
./install/ubuntu.sh
```

This installs: bat, curl, fzf, git, jq, tmux, tree, zsh, GitHub CLI, eza, Go, yq, Oh My Zsh (with autosuggestions and syntax highlighting plugins), NVM, Bun, and pnpm.

### 4. Verify

```bash
./verify.sh
```

## What's Included

### Shell Configuration
- **shell/zshrc** - Zsh configuration with Oh My Zsh
- **shell/zprofile.\*** - Environment variables and PATH setup (per platform)
- **shell/aliases** - Shell aliases and functions

### Git
- **git/gitconfig** - Git configuration with SSH signing via 1Password
- **git/ksyos.gitconfig** - Conditional config for work account
- **git/hooks/** - Git hooks for automation

### Applications
- **homebrew/Brewfile.installed** - Full Homebrew package set
- **homebrew/Brewfile.slim** - Smaller Homebrew package set
- **vscode/** - VS Code editor settings and extensions list
- **.claude/** - Claude CLI local settings

### Utilities
- **bin/** - Custom scripts (port management, VS Code settings sync)
- **scripts/** - Helper scripts (Brewfile sync, SSH setup)
- **install/** - One-time setup scripts (Homebrew, macOS prefs, Ubuntu)

## Directory Structure

```
dotfiles/
├── setup.sh              # Main installer (creates symlinks)
├── uninstall.sh          # Remove symlinks
├── verify.sh             # Verify installation
├── shell/                # Shell configuration
│   ├── zshrc             # Zsh configuration
│   ├── zshrc.macos       # macOS-specific shell config
│   ├── zshrc.linux       # Linux-specific shell config
│   ├── zprofile.macos    # macOS shell profile
│   ├── zprofile.linux    # Linux shell profile
│   └── aliases           # Shell aliases and functions
├── homebrew/             # Homebrew package lists
│   ├── Brewfile.installed # Full package set
│   └── Brewfile.slim      # Smaller package set
├── git/                  # Git configuration
│   ├── gitconfig         # Main git config
│   ├── ksyos.gitconfig   # Work account config
│   └── hooks/            # Git hooks
├── ssh/                  # SSH configuration
├── vscode/               # VS Code settings and extensions
├── zed/                  # Zed editor settings
├── ghostty/              # Ghostty terminal config
├── .claude/              # Claude CLI local settings
├── bin/                  # Custom scripts
├── scripts/              # Helper scripts
├── install/              # Setup scripts
│   ├── brew.sh           # Homebrew installation
│   ├── mac.sh            # macOS preferences
│   └── ubuntu.sh         # Ubuntu packages
└── tools/                # Tools installation
```

## Aliases Reference

### Navigation
| Alias | Description |
|-------|-------------|
| `w` | Navigate to ~/Workspaces |
| `reload` | Reload zsh configuration |

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

## Custom Scripts

### Port Management
```bash
check-port 3000    # Check if port is in use
kill-port 3000     # Kill process on port
```

### VS Code Settings
```bash
save-vscode-extensions     # Backup VS Code extensions
install-vscode-extensions  # Install VS Code extensions
```

## Local Overrides

Files ending in `.local` are sourced but not tracked in git:
- `~/.aliases.local` - Local alias overrides
- `~/.zshrc.local` - Local zsh configuration

## Homebrew

Brewfiles are stored under `homebrew/`:
- **Brewfile.installed** - Full package set for the primary machine
- **Brewfile.slim** - Smaller package set for lean installs

### Sync system with Brewfile
```bash
# Check what's missing (dry run)
brew bundle check --file=homebrew/Brewfile.installed

# Install missing packages
brew bundle --file=homebrew/Brewfile.installed

# See what would be installed
brew bundle list --file=homebrew/Brewfile.installed
```

Replace `Brewfile.installed` with `Brewfile.slim` for a smaller install.

### Update Brewfiles from system (preserving comments)
```bash
# See what would change (dry run)
./scripts/brew-update.sh -n Brewfile.installed

# Add newly installed packages
./scripts/brew-update.sh Brewfile.installed

# Also remove uninstalled packages
./scripts/brew-update.sh -r Brewfile.installed
```

The update script compares installed packages with your Brewfile and:
- Keeps existing entries with comments intact
- Adds new packages that you've installed
- Optionally removes packages no longer installed (`-r` flag)

### Cleanup unused packages
```bash
brew bundle cleanup --force --file=homebrew/Brewfile.installed  # or Brewfile.slim
```

## Verification

Run the verification script to check your installation:
```bash
./verify.sh
```

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
chmod +x bin/*
```

### 1Password SSH signing not working
```bash
# Set local SSH program for specific repo
git config --local gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
```

## Credits

Inspired by:
- [anhari.dev - Saving VSCode settings in your dotfiles](https://anhari.dev/blog/saving-vscode-settings-in-your-dotfiles)
