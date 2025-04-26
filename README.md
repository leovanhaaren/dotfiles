# Dotfiles

Based on;

- <https://github.com/thoughtbot/dotfiles>
- <https://anhari.dev/blog/saving-vscode-settings-in-your-dotfiles>

## Tools

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

## Helpful commands

```bash
# Set local ssh program in case obsidian does not work
git config --local gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
```