# Homebrew

Manages Homebrew packages, casks, Mac App Store apps, VS Code extensions, and Go packages through base and work Brewfiles.

## Installation

### Prerequisites

Install Homebrew separately after reviewing the official instructions at <https://brew.sh>.
The repository script is non-mutating by default:

```bash
./scripts/brew.sh
```

It prints the selected `Brewfile.base` plan without invoking Homebrew.
Apply package changes explicitly:

```bash
./scripts/brew.sh --apply
./scripts/brew.sh --apply Brewfile.work
```

Pass `--cleanup` with `--apply` only when Homebrew cleanup is also intended.

### Install directly with brew bundle

```bash
brew bundle --file=homebrew/Brewfile.base
```

### Move Homebrew to an external APFS volume

Preview the migration first:

```bash
./scripts/homebrew-ssd.sh --container disk5
```

Apply it only after checking the selected container:

```bash
sudo ./scripts/homebrew-ssd.sh --container disk5 --apply
```

The migration verifies volume ownership, refuses non-empty pre-existing destination volumes, runs Homebrew checks as the non-root owner, stores temporary files under root-owned `/private/var/db/homebrew`, retains `/opt/homebrew.bak`, and restores automount files if a late step fails.
Re-running apply mode on an existing migration repairs the automount files without copying Homebrew again.

## Usage

### Uninstall specific packages

1. Remove the corresponding lines from `Brewfile.base`
2. Preview what will be uninstalled:

   ```bash
   brew bundle cleanup --file=homebrew/Brewfile.base
   ```

3. Apply the cleanup:

   ```bash
   brew bundle cleanup --file=homebrew/Brewfile.base --force
   ```

### Check what's missing or outdated

```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file=homebrew/Brewfile.base
```

## Brewfile sections

| Section | Prefix | Description |
| ------- | ------ | ----------- |
| Taps | `tap` | Third-party Homebrew repositories |
| CLI Tools | `brew` | Command-line formulae |
| Desktop Apps | `cask` | GUI applications |
| App Store | `mas` | Mac App Store apps (requires `mas`) |
| VS Code | `vscode` | VS Code extensions |
| Go Packages | `go` | Go binaries installed via `go install` |
