# Nix adoption plan

Goal: migrate this repo from Stow + Homebrew scripts to a declarative Nix flake, without a big-bang cutover and without losing the current dry-run-first safety model.

## Target architecture

- One flake at the repo root with **nix-darwin** (system layer) and **home-manager** as a nix-darwin module (user layer).
- **Determinate Nix installer** for install/uninstall hygiene and survival across macOS upgrades.
- **nix-homebrew / nix-darwin `homebrew` module** keeps casks and Mac App Store apps in Homebrew, but declared in Nix. GUI apps stay on Homebrew indefinitely; that is the accepted end state, not a compromise.
- Per-host outputs: `darwinConfigurations."macbook"`, `"mac-mini"`, shared modules under `modules/`, host deltas under `hosts/`.
- Work vs personal split (mirrors `Brewfile.base` / `Brewfile.work`): a `work.nix` module toggled per host.

Repo layout end state:

```
flake.nix
flake.lock
hosts/
  macbook.nix
  mac-mini.nix
modules/
  darwin/        # system defaults, homebrew casks
  home/          # programs.*, dotfile links
```

## Phased migration

Each phase is independently shippable and reversible. Stow and Nix coexist safely as long as they never manage the same target path.

### Phase 0 - Install Nix (no repo changes)

1. Install via the Determinate installer.
2. Verify: `nix run nixpkgs#hello`, `nix flake --help`.
3. Rollback path: the installer has a documented uninstall.

### Phase 1 - Flake skeleton + CLI packages

1. Add `flake.nix` with nix-darwin + home-manager for this machine only.
2. Move the pure CLI formulae from `Brewfile.base` (the ~48 `brew` entries: git, gh, mise, fish, nvim, tmux, stow, etc.) into `home.packages` / `programs.*`.
3. Declare the ~30 casks via the nix-darwin `homebrew.casks` option with `cleanup = "none"` initially (nothing gets uninstalled).
4. First activation: `darwin-rebuild switch --flake .` — dry-run first with `darwin-rebuild build --flake .` and inspect the diff (`nvd diff /run/current-system ./result`).
5. Remove migrated formulae from `Brewfile.base` only after verifying the Nix-provided binaries win on `PATH`.

Exit criteria: `brew list --formula` is empty or near-empty; `verify.sh` still passes.

### Phase 2 - Dotfiles into home-manager

Migrate file-by-file, lowest risk first. For each file: remove the Stow link, add either `home.file`/`xdg.configFile` (verbatim source, zero rewrite risk) or a native `programs.<tool>` module (more declarative, more rewrite).

Recommended order:

1. Verbatim links first: `.aliases`, `.functions`, `.tmux.conf`, `.gitmux.conf`, `.config/*` (starship, ghostty, wezterm, aerospace, sesh, ...). Use `mkOutOfStoreSymlink` pointing into the repo so edits stay live without a rebuild — this preserves the current edit-in-repo workflow.
2. Git: `programs.git` with the 1Password SSH-signing config and the ksyos conditional include.
3. Zsh: `programs.zsh`. Decide here whether to keep Oh My Zsh (home-manager supports it) or replace it with `programs.zsh.autosuggestion` + `syntaxHighlighting` natively — the current `.zshrc` only uses OMZ for those two plugins plus the git plugin, so dropping OMZ is a small, worthwhile simplification.
4. SSH: `programs.ssh` last — host configs change often here (recent commits), and secrets/keys stay in 1Password (`op-agent` workflow unchanged; Nix manages config, never key material).

Exit criteria: `.stow-local-ignore` and Stow usage in `setup.sh` are empty; `setup.sh` reduced to "run darwin-rebuild".

### Phase 3 - macOS defaults and system layer

1. Port `scripts/mac.sh` preferences to `system.defaults.*` in nix-darwin. Port only what nix-darwin supports natively; keep a small activation script for the rest (display settings, screensaver toggles) rather than fighting the module system.
2. Keep the opt-in behaviors (`--install-system-updates` etc.) out of the declarative config — those stay imperative by design.

### Phase 4 - Multi-host rollout

1. Add `hosts/mac-mini.nix`; bootstrap the second machine from the flake (`nix run nix-darwin -- switch --flake github:leovanhaaren/dotfiles`).
   On a machine that keeps Homebrew on a separate SSD volume, provision the volume first so Homebrew never touches the internal disk: `sudo scripts/homebrew-ssd.sh --container <disk> --provision --apply`, then `./install.sh --nix --apply` (nix-homebrew installs onto the mounted volume).
2. Move host-specific values (hostname, work module on/off) into host files.
3. `flake.lock` becomes the cross-machine version pin, replacing ad-hoc brew versions.

### Phase 5 - Cleanup

1. Delete `setup.sh` stow logic, `uninstall.sh`, `scripts/brew.sh`, Brewfiles (casks now live in Nix config), `.stow-local-ignore`.
2. Rewrite `README.md` around `darwin-rebuild`.
3. Rewrite `verify.sh` to check the Nix generation instead of Stow links.

## Deliberately out of scope

- **Neovim plugins**: keep lazy.nvim with its machine-local lockfile. Nixifying nvim plugins is high-effort, low-reward.
- **mise**: keep it for per-project tool versions initially; Nix devShells/direnv can replace it later per-project, not as part of this migration.
- **Secrets**: stay in 1Password. No agenix/sops-nix needed since nothing secret lives in the repo today — keep it that way.
- **VS Code settings**: keep the current manual symlink; `programs.vscode` fights Settings Sync.
- **VS Code extensions**: the nix-darwin homebrew module has no `vscode` support, so the `vscode` entries stay in `Brewfile.base` (installed on the classic path only). On Nix machines install them manually with `code --install-extension`, or via Settings Sync.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Stow and home-manager both claim a file | Migrate per-file; home-manager refuses to clobber existing files by default |
| Nix binary vs brew binary PATH conflicts during Phase 1 | Keep brew shellenv last in PATH order; verify with `which` per tool |
| Bad activation breaks shell | `darwin-rebuild --rollback`; generations make every switch reversible |
| macOS update breaks Nix | Determinate installer handles this; worst case reinstall, config is all in git |
| Brewfile.work drift | Port `Brewfile.work` into the work module in Phase 1 alongside base |

## Maintenance

- **Garbage collection is manual.** With `nix.enable = false` (Determinate manages the daemon), nix-darwin's `nix.gc.automatic` is unavailable, and every switch keeps a rollback generation forever. Periodically:
  1. `darwin-rebuild --list-generations` to review what exists.
  2. `sudo nix-collect-garbage --delete-older-than 30d` to drop old generations and reclaim store space.
  Keep at least one known-good older generation around before collecting.

## Effort estimate

- Phase 0-1: one evening.
- Phase 2: the bulk — spread over 1-2 weeks, one file/tool at a time.
- Phase 3-5: an evening each.
