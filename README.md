# Dotfiles

Personal dotfiles for macOS development environment.

## Quick Start

```bash
# Clone the repository
git clone git@github.com:leovanhaaren/dotfiles.git ~/Workspaces/leovanhaaren/dotfiles

# Create symlinks
cd ~/Workspaces/leovanhaaren/dotfiles
./setup.sh

# Install Homebrew packages (optional)
./installers/brew.sh

# Apply macOS preferences (optional)
./installers/mac.sh
```

## What's Included

### Shell Configuration
- **zshrc** - Zsh configuration with Oh My Zsh
- **zprofile** - Environment variables and PATH setup
- **aliases** - Shell aliases and functions

### Git
- **gitconfig** - Git configuration with SSH signing via 1Password
- **git/** - Additional git configs for multiple accounts

### Applications
- **Brewfile** - Homebrew packages, casks, and VS Code extensions
- **vscode-settings/** - VS Code editor configuration
- **claude/** - Claude CLI settings for different contexts

### Utilities
- **bin/** - Custom scripts (port management, VS Code settings sync)
- **hooks/** - Git hooks for automation

## Directory Structure

```
dotfiles/
├── setup.sh              # Main installer (creates symlinks)
├── uninstall.sh          # Remove symlinks
├── verify.sh             # Verify installation
├── zshrc                 # Zsh configuration
├── zprofile              # Shell profile
├── aliases               # Shell aliases and functions
├── gitconfig             # Git configuration
├── Brewfile              # Homebrew packages
├── bin/                  # Custom scripts
├── claude/               # Claude CLI configs
├── git/                  # Git include files
├── installers/           # Setup scripts
│   ├── brew.sh           # Homebrew installation
│   └── mac.sh            # macOS preferences
├── scripts/              # Helper scripts
├── vscode-settings/      # VS Code configuration
└── hooks/                # Git hooks
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
| `cc` | Run Claude with pass-cli |
| `cc-glm` | Switch to GLM Claude config |
| `cc-reset` | Reset to default Claude config |
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

### Update Brewfile from installed packages
```bash
brew bundle dump --file=~/Workspaces/leovanhaaren/dotfiles/Brewfile --force
```

### Install packages from Brewfile
```bash
brew bundle --file=~/Workspaces/leovanhaaren/dotfiles/Brewfile
```

### Cleanup unused packages
```bash
brew bundle cleanup --force --file=~/Workspaces/leovanhaaren/dotfiles/Brewfile
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
