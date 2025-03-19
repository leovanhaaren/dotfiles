# Dotfiles

Based on;

- <https://github.com/thoughtbot/dotfiles>
- <https://anhari.dev/blog/saving-vscode-settings-in-your-dotfiles>

## Tools

- <https://github.com/thoughtbot/rcm>

## Use the rcup command to pull files from ~/dotfiles to the root

```bash
rcup
```

## Use the mkrc command to push the file from ~/ into your ~/dotfiles repo

```bash
mkrc
```

## Dump Brewfile

```bash
brew bundle dump --file=~/.Brewfile
```

## Cleanup
```bash
brew bundle cleanup --force
```

## permissions denied

```bash
Make executable; ```chmod +x ~/dotfiles/bin/save_code_extensions
```
