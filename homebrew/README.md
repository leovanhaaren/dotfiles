# Homebrew

Manages all Homebrew packages, casks, Mac App Store apps, VS Code extensions, and Go packages via a single Brewfile.

## Usage

### Install everything

```bash
brew bundle --file=homebrew/Brewfile.installed
```

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
|---------|--------|-------------|
| Taps | `tap` | Third-party Homebrew repositories |
| CLI Tools | `brew` | Command-line formulae |
| Desktop Apps | `cask` | GUI applications |
| App Store | `mas` | Mac App Store apps (requires `mas`) |
| VS Code | `vscode` | VS Code extensions |
| Go Packages | `go` | Go binaries installed via `go install` |
