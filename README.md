# Dotfiles

Personal dotfiles for macOS development environments.

## Installation

### Prerequisites

- macOS
- Git
- Bash
- GNU Stow
- Homebrew for package installation

### 1. Clone the Repository

```bash
git clone git@github.com:leovanhaaren/dotfiles.git ~/Workspaces/leovanhaaren/dotfiles
cd ~/Workspaces/leovanhaaren/dotfiles
```

### 2. Create Symlinks via GNU Stow

```bash
./setup.sh          # dry run
./setup.sh --apply  # create links
```

Setup creates the macOS links for shell config, Git, SSH, editor settings, and custom scripts.
Conflicting Stow targets fail safely by default.
Use `--adopt` only as an explicit migration after reviewing the dry run; apply mode requires a clean Git tree and creates a repository bundle under `backups/`.
TPM and tmux plugins are not downloaded automatically.
Run `tmux-plugins sync` to preview the pinned plugin installation and `tmux-plugins sync --apply` to install the reviewed revisions.
Neovim dependencies are likewise locked in `.config/nvim/lazy-lock.json`.

### 3. Install Packages

```bash
# Preview or install Homebrew packages
./scripts/brew.sh
./scripts/brew.sh --apply
./scripts/brew.sh --apply Brewfile.work

# Preview or apply macOS preferences
./scripts/mac.sh
./scripts/mac.sh --apply
./scripts/mac.sh --apply --apply-display --disable-screensaver-password

# System updates require a separate opt-in
./scripts/mac.sh --apply --install-system-updates
```

### 4. Verify

```bash
./verify.sh
```

## What's Included

### Shell Configuration
- **.zshrc** - Zsh configuration with Oh My Zsh (stowed to `~/`)
- **.zprofile** - Environment variables and PATH setup (stowed to `~/`)
- **.aliases** - Shell aliases (stowed to `~/`)
- **.functions** - Shell functions (commit, acp, git worktrees, etc.) (stowed to `~/`)
- **.config/fish/** - Fish shell configuration (stowed to `~/.config/fish/`)

### Git
- **.gitconfig** - Git configuration with SSH signing via 1Password (stowed to `~/`)
- **.config/git/ksyos.gitconfig** - Conditional config for work account (stowed to `~/.config/git/`)
- **.config/git/hooks/** - Git hooks for automation (stowed to `~/.config/git/`)

### Applications
- **homebrew/Brewfile.base** - Primary Homebrew package set
- **homebrew/Brewfile.work** - Work-specific packages (1Password, AWS, etc.)
- **vscode/settings.json** - VS Code editor settings (symlinked manually on each OS)
- **vscode/extensions.list** - VS Code extensions captured by the repository pre-commit hook

### Terminal Emulators
- **.tmux.conf** - Tmux configuration with TPM, Catppuccin theme, resurrect, floax (stowed to `~/`)
- **.gitmux.conf** - Git status in tmux status bar (stowed to `~/`)
- **.config/wezterm/wezterm.lua** - Wezterm configuration (stowed to `~/.config/wezterm/`)
- **.config/ghostty/config** - Ghostty terminal configuration (stowed to `~/.config/ghostty/`)

### Window Management
- **.config/aerospace/aerospace.toml** - AeroSpace window manager configuration (stowed to `~/.config/aerospace/`)
  - Do not also create `~/.aerospace.toml`; AeroSpace errors when both config locations exist.

### Session Management
- **.config/sesh/sesh.toml** - Sesh session manager configuration (stowed to `~/.config/sesh/`)
- **.config/television/** - Television fuzzy finder and agent session channels (stowed to `~/.config/television/`)
- **bin/agent-sessions** - Lists, previews, and resumes local Claude, Codex, OpenCode, and Pi sessions
- **bin/sesh-picker** - Encodes Sesh and Herdr selections before Television actions execute them
- **.config/worktrunk/config.toml** - Worktrunk git worktree manager (stowed to `~/.config/worktrunk/`)

### Other Tools
- **.config/starship.toml** - Starship prompt configuration (stowed to `~/.config/`)
- **.config/mise/config.toml** - Mise version manager config (stowed to `~/.config/mise/`)
- **.config/zed/settings.json** - Zed editor settings (stowed to `~/.config/zed/`)

### GitHub SSH key management

`create-github-ssh-key` creates a separate Ed25519 authentication or signing key in the 1Password `Employee` vault, streams the same private key into the Proton Pass `SSH` vault, and uploads only its public key to the active `leo-ksyos` GitHub account.
Authentication mode configures `github.com-ksyos` to use the 1Password SSH agent.
Signing mode writes the public key and 1Password `op-ssh-sign` program to the work Git config, then creates and verifies a signed commit in a disposable local repository.
The command defaults to authentication and a non-mutating dry run, and it never stores the private key as a regular local file.

```bash
# Authentication key
gh auth refresh -h github.com -s admin:public_key
create-github-ssh-key
create-github-ssh-key --apply

# Separate signing key
gh auth refresh -h github.com -s admin:ssh_signing_key
create-github-ssh-key --type signing
create-github-ssh-key --type signing --apply
```

The apply preflight verifies the active GitHub account, both vaults, the required type-specific GitHub scope, and the required 1Password integration before creating anything.
If a run stops after creating its 1Password item, repeat it with the exact reported title, key type, and `--apply --resume`.
Changed local public keys and SSH or Git configuration are backed up under `~/.ssh/backups/create-github-ssh-key/`.
Existing GitHub keys are intentionally retained for manual removal after normal Git operations have been verified.
Use `create-github-ssh-key --help` to override the type, account, host alias, vaults, title, signing program, or paths.

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
├── bin/                       # Commands stowed to ~/bin/
│   ├── agent-sessions         # Browse and resume coding-agent sessions
│   ├── create-github-ssh-key  # Create and distribute a GitHub SSH key safely
│   ├── nvim-plugins           # Verify installed Neovim plugin integrity
│   ├── save-vscode-extensions # Safely capture the extension list
│   ├── sesh-picker            # Safely dispatch Television session actions
│   └── tmux-plugins           # Verify or install locked tmux plugins
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
│   └── config.macos      #   macOS SSH config
│
├── vscode/               # VS Code settings (not stowed, linked by setup.sh)
│   ├── settings.json
│   └── extensions.list
│
├── tmux/plugins.lock          # Reviewed tmux plugin revisions
│
├── scripts/                   # Setup and utility scripts (not stowed)
│   ├── lib/managed-links.sh   # Shared lifecycle ownership manifest
│   ├── tests/                 # Regression and safety checks
│   ├── brew.sh                # Homebrew bundle workflow
│   ├── mac.sh                 # macOS preferences
│   ├── homebrew-ssd.sh        # Transactional external-SSD migration
│   └── ssh-load-keys.sh       # Load SSH keys from Proton Pass
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
| `gwl` | List worktrees with Worktrunk |
| `gwa` | Create and switch to a Worktrunk worktree |
| `gwr` | Remove a worktree with Worktrunk |
| `gwab <branch>` | Create and switch to a new branch worktree |
| `gwae <branch>` | Switch to an existing branch worktree |
| `gwao <branch>` | Switch to an origin branch without installing dependencies |
| `gwcd <name>` | Switch to a matching worktree |

### Claude Code
| Alias | Description |
|-------|-------------|
| `zai` | Run Claude with z.ai config |
| `mm` | Run Claude with minimax config |
| `ccc` | Run Claude in container |

### Tmux
| Alias | Description |
|-------|-------------|
| `s` | Launch Sesh session picker |
| `a` | Launch agent session picker |
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
Its fuzzy search also indexes bounded conversation text from those local transcripts without displaying it in the results list.
It obtains OpenCode sessions through `opencode session list`, grouped by projects reported by `opencode debug scrap`.
OpenCode search is limited to session metadata because exporting every transcript would make the picker slow.
Session previews stay local and show only the selected transcript.

### Decisions

- Agent conversations use a separate Television channel instead of overloading Sesh's connect action.
- Both picker commands carry opaque encoded records so titles and filesystem paths cannot alter shell commands.
- Neovim and tmux plugin code executes only from clean checkouts at reviewed revisions recorded in lock files.
- Mutating picker actions default to a dry run; Television passes `--apply` only for an explicit key action.
- Missing or malformed session files are skipped so one dirty history cannot break the picker.
- Setup, uninstall, package installation, macOS preferences, and SSD migration expose non-mutating defaults and require `--apply` for writes.
- Setup, uninstall, and verification share one manual-link ownership manifest so lifecycle behavior remains symmetric.

## Custom Functions

### AI-Assisted Commits
```bash
commit        # Stage? No. Generate message from staged diff, confirm, commit
acp           # Stage all, generate message, commit, push
```

Both send the staged diff to `pi` through the configured GitHub Copilot provider to generate Conventional Commit messages.
Generation, commit, and push failures return nonzero and never print a false success message.

### Git Worktrees
```bash
gwab <branch>   # Create new branch worktree
gwae <branch>   # Add existing branch worktree
gwao <branch>   # Add worktree tracking origin branch
gwcd <name>     # Navigate to worktree by name
```

## Local Overrides

Files ending in `.local` are sourced but not tracked in git:
- `~/.aliases.local` - Local alias overrides
- `~/.zshrc.local` - Local zsh configuration
- `~/.tmux.conf.local` - Local tmux configuration

## Homebrew

Brewfiles are stored under `homebrew/`:
- **Brewfile.base** - Primary package set for the main machine
- **Brewfile.work** - Work-specific packages (1Password, AWS CLI, etc.)

### Repair the moshi-hook service

Homebrew regenerates the `moshi-hook` LaunchAgent during service restarts.
On a separately mounted Homebrew volume, macOS can block launchd from accessing the generated log path under `/opt/homebrew/var/log`.
Run the repair command after `brew services start` or `brew services restart` leaves `moshi-hook` loaded but not running:

```bash
repair-moshi-hook          # Preview the repair
repair-moshi-hook --apply  # Patch, reload, and verify the service
```

The command redirects launchd output to `/dev/null` because `moshi-hook` maintains its own log at `~/Library/Application Support/Moshi/hook.log`.
A later Homebrew service restart can regenerate the broken paths, so rerun the repair when needed.

### Sync system with Brewfile
```bash
# Check what is missing without Homebrew auto-update
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file=homebrew/Brewfile.base

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

Run the complete repository checks:

```bash
./verify.sh
bun test scripts/tests/*.test.ts
scripts/tests/lifecycle-safety.sh
scripts/tests/stow-lifecycle.sh
scripts/tests/tmux-bindings.sh
agent-sessions list | head
sesh-picker list all | head
nvim-plugins verify
tmux-plugins verify
repair-moshi-hook
```

The Bun tests cover both picker record formats, shell-sensitive selections, lifecycle invariants, and agent-session behavior.
The lifecycle tests prove that defaults do not write and that a real isolated setup, verification, and uninstall round trip succeeds.
`tv list-channels` should include `agent-sessions` and `sesh` after setup.
On macOS with `moshi-hook` installed, the final command must report only the planned repair and must not modify the LaunchAgent.

## Troubleshooting

### Symlinks not working
```bash
# Preview and remove repository-owned symlinks
./uninstall.sh
./uninstall.sh --apply

# Preview and recreate symlinks
./setup.sh
./setup.sh --apply
```

### Permission denied on scripts
```bash
chmod +x setup.sh uninstall.sh verify.sh
chmod +x bin/* scripts/*.sh scripts/tests/*.sh
```

### 1Password SSH signing not working
```bash
# Set local SSH program for specific repo
git config --local gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
```

## Credits

Inspired by:
- [anhari.dev - Saving VSCode settings in your dotfiles](https://anhari.dev/blog/saving-vscode-settings-in-your-dotfiles)
