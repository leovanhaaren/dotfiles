# Homebrew

Manages all Homebrew packages, casks, Mac App Store apps, VS Code extensions, and Go packages via a single Brewfile.

## Installation

### Prerequisites

If Homebrew is not installed yet, the install script will set it up automatically. You can also run the full installation via:

```bash
./install/brew.sh
```

This will:

1. Install Homebrew if missing
2. Update Homebrew recipes
3. Install all packages from the default Brewfile (`Brewfile.personal`)

To install from a specific Brewfile:

```bash
./install/brew.sh Brewfile.installed
```

### Install directly with brew bundle

```bash
brew bundle --file=homebrew/Brewfile.installed
```

## Usage

### Uninstall specific packages

1. Remove the corresponding lines from `Brewfile.installed`
2. Preview what will be uninstalled:

   ```bash
   brew bundle cleanup --file=homebrew/Brewfile.installed
   ```

3. Apply the cleanup:

   ```bash
   brew bundle cleanup --file=homebrew/Brewfile.installed --force
   ```

### Check what's missing or outdated

```bash
brew bundle check --file=homebrew/Brewfile.installed
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
