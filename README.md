# Dotfiles

Personal dotfiles for macOS and Linux development environments.

## Quick Start

```bash
# Clone the repository
git clone git@github.com:leovanhaaren/dotfiles.git ~/Workspaces/leovanhaaren/dotfiles

# Create symlinks
cd ~/Workspaces/leovanhaaren/dotfiles
./setup.sh

# Install Homebrew packages (optional)
./install/brew.sh                    # defaults to Brewfile.personal
./install/brew.sh Brewfile.work      # for work machines

# Apply macOS preferences (optional)
./install/mac.sh
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
- **homebrew/Brewfile.base** - Shared Homebrew packages for all machines
- **homebrew/Brewfile.personal** - Personal machine packages (includes base)
- **homebrew/Brewfile.work** - Work machine packages (includes base)
- **vscode/** - VS Code editor settings and extensions list
- **claude/** - Claude CLI settings for different contexts

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
│   ├── Brewfile.base     # Shared packages
│   ├── Brewfile.personal # Personal machine packages
│   └── Brewfile.work     # Work machine packages
├── git/                  # Git configuration
│   ├── gitconfig         # Main git config
│   ├── ksyos.gitconfig   # Work account config
│   └── hooks/            # Git hooks
├── ssh/                  # SSH configuration
├── vscode/               # VS Code settings and extensions
├── zed/                  # Zed editor settings
├── ghostty/              # Ghostty terminal config
├── claude/               # Claude CLI configs
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
save_code_settings     # Backup VS Code settings
restore_code_settings  # Restore VS Code settings
```

## Local Overrides

Files ending in `.local` are sourced but not tracked in git:
- `~/.aliases.local` - Local alias overrides
- `~/.zshrc.local` - Local zsh configuration

## Homebrew

Brewfiles are split into three files under `homebrew/`:
- **Brewfile.base** - Packages shared across all machines
- **Brewfile.personal** - Personal-only packages (Proton apps, home automation, etc.)
- **Brewfile.work** - Work-only packages (AWS tools, containers, 1Password, etc.)

### Sync system with Brewfile
```bash
# Check what's missing (dry run)
brew bundle check --file=homebrew/Brewfile.personal

# Install missing packages
brew bundle --file=homebrew/Brewfile.personal

# See what would be installed
brew bundle list --file=homebrew/Brewfile.personal
```

Replace `Brewfile.personal` with `Brewfile.work` for work machines.

### Update Brewfiles from system (preserving comments)
```bash
# See what would change (dry run)
./scripts/brew-update.sh -n Brewfile.base

# Add newly installed packages
./scripts/brew-update.sh Brewfile.base

# Also remove uninstalled packages
./scripts/brew-update.sh -r Brewfile.base
```

The update script compares installed packages with your Brewfile and:
- Keeps existing entries with comments intact
- Adds new packages that you've installed
- Optionally removes packages no longer installed (`-r` flag)

### Cleanup unused packages
```bash
brew bundle cleanup --force --file=homebrew/Brewfile.personal  # or Brewfile.work
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
