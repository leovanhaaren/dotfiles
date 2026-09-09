# Nix adoption plan for declarative macOS dotfiles

## Purpose and scope

Adopt Nix incrementally for this macOS dotfiles repository without disrupting the currently working Homebrew, GNU Stow, Mise, SSH, 1Password, Proton Pass, or application setup.

The target is one flake-locked Apple Silicon host configuration using `nix-darwin` for machine-level Nix integration and Home Manager for user packages and dotfiles.

The migration begins with user-level configuration and CLI tools.

It deliberately does not replace every macOS capability in the first release.

Homebrew continues to own GUI casks, Mac App Store applications, Homebrew services, and packages with an unacceptable Nix compatibility gap until each item has been audited.

## Evidence and starting position

| Item | Observed state | Adoption implication |
| --- | --- | --- |
| Platform | macOS 26.5.1, `arm64`, host `MacBook-Pro-van-Leo` | Use `aarch64-darwin` and one host output initially. |
| Nix | Not installed | Install and validate Nix before adding configuration ownership. |
| Current configuration manager | GNU Stow manages 21 checked configuration targets and 8 `~/bin` scripts, with 4 manually managed links | Do not give Stow and Home Manager ownership of the same target. |
| Packages | Two Brewfiles contain 53 formulae, 30 casks, 3 App Store applications, 12 VS Code extensions, and 4 Go packages | Audit each item rather than attempting a bulk replacement. |
| Language runtimes | Mise owns Bun, Node, and pnpm | Keep Mise as the runtime/version manager initially to avoid duplicate ownership. |
| Current verification | `./verify.sh` fails because `~/.config/git/hooks/pre-commit` and `pre-push` are regular files rather than the Stow-owned links | Repair or explicitly classify these hook files before any migration. |
| Current Git worktree | `main` at `65add18`, with an existing modification in `.config/git/ksyos.gitconfig` | Preserve that unrelated work and do not use `stow --adopt`. |

## Chosen architecture

Use a small, conventional flake rather than adding a framework such as flake-parts during the initial adoption.

```text
flake.nix
flake.lock
nix/
  hosts/macbook-pro-van-leo/default.nix
  home/default.nix
  home/modules/
    packages.nix
    files.nix
    shell.nix
    git.nix
    terminal.nix
    editors.nix
  lib/ownership.nix
scripts/
  nix-rebuild.sh
```

`flake.nix` will pin these inputs in `flake.lock`:

- `nixpkgs`, on a consciously selected supported release branch.
- `nix-darwin`, following the same `nixpkgs` input.
- `home-manager`, following the same `nixpkgs` input.

The Darwin host output will be named `macbook-pro-van-leo` and will explicitly set `nixpkgs.hostPlatform = "aarch64-darwin"`.

Home Manager will be imported through `home-manager.darwinModules.home-manager`, so one `darwin-rebuild` activation applies both system and user configuration.

Set `system.stateVersion` and `home.stateVersion` only once during bootstrap, then treat both as compatibility contracts rather than version numbers to update routinely.

Enable `nix-command` and `flakes` in the managed Nix settings.

Use only the default official binary cache during bootstrap.

Add third-party substituters, extra trusted users, unfree-package rules, or remote builders only when a concrete package requires them and the security impact has been reviewed.

## Ownership model

The central invariant is: **one target path has one writer**.

| Owner | Initial responsibility | Explicitly not responsible for initially |
| --- | --- | --- |
| Nix daemon and nix-darwin | Nix installation settings, pinned package graph, Darwin rebuild generations | Broad macOS preference conversion and application installation. |
| Home Manager | User-level Nix packages and migrated static files under `$HOME` and `$XDG_CONFIG_HOME` | Files that applications rewrite, all shell semantics, credentials, and macOS Library paths. |
| GNU Stow | All currently managed targets not yet migrated | Any Home Manager-owned target. |
| Homebrew | Casks, App Store support, Homebrew services, unsupported packages, and retained formulae | Nix-owned CLI packages once their Brewfile entry has been intentionally removed. |
| Mise | Bun, Node, pnpm, and project runtime versions | System-level command installation. |
| Existing scripts | SSH key workflow, secret references, macOS preferences, tmux and Neovim plugin locks | Nix Store secrets and cross-owner cleanup. |

Home Manager-managed files must never contain credentials, private keys, access tokens, or machine-local values because their material is stored in the Nix store.

Keep the existing `.local` shell override convention and keep credential values in 1Password, Proton Pass, Keychain, or other existing secret systems.

Do not place `~/.ssh/config`, VS Code settings in `~/Library`, rtk settings in `~/Library`, or Neovim's generated `lazy-lock.json` under Home Manager in the first release.

## Phased execution plan

### Phase 0 - Establish a safe baseline

1. Record the repository root, branch, HEAD, and working-tree status before every mutation.
2. Preserve the existing change to `.config/git/ksyos.gitconfig` and do all adoption work in a dedicated branch or worktree.
3. Resolve the two Git-hook conflicts reported by `./verify.sh`.
   Inspect their content and ownership first.
   Either restore the repository-managed symlinks, or deliberately update the Stow ownership manifest if local hooks are intended.
   Do not run `setup.sh --adopt` while the worktree is dirty.
4. Make the existing validation suite pass before moving ownership:
   `./verify.sh`, Bun tests, lifecycle tests, tmux binding checks, plugin verifiers, and Homebrew bundle checks.
5. Capture a non-secret inventory outside the repository for rollback comparison:
   command paths and versions, enabled Homebrew services, current Git configuration origins, `launchctl` state for any retained service, and the output of `brew bundle list` for both Brewfiles.
6. Create a package ownership worksheet with one row per Brewfile entry:
   package, current command path, Nix availability on `aarch64-darwin`, replacement name, required behavior, owner after migration, test command, and rollback command.

**Exit criterion:** the Stow verifier is green, the baseline outputs are recorded, and every current package has an initial owner classification.

### Phase 1 - Install and validate Nix only

1. Use the official multi-user Nix installation method for macOS after reviewing its current documentation.
   Do not use the single-user installer.
2. Confirm the installer supports the running macOS version and has a documented uninstallation procedure before applying it.
3. Validate the installation without migrating configuration:
   `nix --version`, `nix doctor`, `nix show-config`, and a temporary `nix shell` for an innocuous CLI tool.
4. Confirm flakes are enabled and that the daemon and `/nix` Store volume survive a fresh login.
5. Keep `/opt/homebrew/bin` first in the existing shell path during this phase.
   This avoids accidental changes to the commands currently executed by shell startup files.

**Exit criterion:** Nix is available to a new login shell, has no daemon or Store errors, and no existing command or dotfile target has changed owner.

**Rollback:** use the uninstall procedure documented by the selected installer.
No Homebrew, Stow, or dotfile rollback is necessary because none has been migrated.

### Phase 2 - Bootstrap and evaluate the flake

1. Add the minimal flake structure described above.
2. Configure the current host only, with `aarch64-darwin` and user home `/Users/l.vanhaaren`.
3. Integrate Home Manager as a nix-darwin module.
4. Add a `nix-rebuild.sh` wrapper that follows repository safety conventions:
   it prints the selected host and evaluation plan by default, builds or activates only with explicit modes, and never calls garbage collection automatically.
5. Add a non-mutating configuration check that evaluates the Darwin output and Home Manager activation package.
6. Run `nix flake check` and `darwin-rebuild build --flake .#macbook-pro-van-leo` before the first switch.
7. Apply the first switch only after reviewing the build result and recording the current Darwin generation.

The bootstrap configuration should contain only Nix settings and a deliberately small package such as `hello` or `ripgrep`.
It must not yet manage a file in `$HOME`.

**Exit criterion:** `darwin-rebuild switch --flake .#macbook-pro-van-leo` succeeds, a fresh terminal can find the test package through the intended Nix profile path, and Stow verification still passes unchanged.

**Rollback:** switch to the immediately previous Darwin generation using the installed `darwin-rebuild` rollback mechanism, then verify the current command paths again.
Keep the previous generation until the full migration is accepted.

### Phase 3 - Migrate CLI packages by small cohorts

Migrate packages only after the worksheet proves the Nix package has the required behavior on Apple Silicon.

Start with independent command-line utilities such as `bat`, `eza`, `fd`, `fzf`, `jq`, `ripgrep`, `shellcheck`, `starship`, `tree`, `yq`, and `zoxide`.

For each cohort:

1. Add the exact Nix package to `home.packages` or a program module.
2. Build and activate the host configuration.
3. Compare version, executable path, completion behavior, and one task-relevant command using `type -a`, `command -v`, and the worksheet test.
4. Decide which package manager is authoritative in `PATH`.
5. Only after successful comparison, remove the corresponding formula from the relevant Brewfile.
6. Do not invoke Homebrew cleanup yet.
7. Commit the Nix module, lock-file update, Brewfile deletion, worksheet update, and verification result as one atomic migration change.

Retain the following initially:

- All 30 Homebrew casks and all 3 Mac App Store applications.
- Homebrew services and their operational scripts, especially `moshi-hook` and its external-SSD repair workflow.
- Custom-tap formulae such as `llmfit`, `moshi-hook`, `pass-cli`, `tuicr`, `models`, `taproom`, `hunk`, and `pup` until audited individually.
- 1Password, Proton Pass, SSH-agent tooling, and cloud/vendor CLIs until their integration and signing behavior are verified.
- Mise-managed language runtimes.
- `go install` packages unless their lifecycle is intentionally converted to Nix.

**Exit criterion:** every migrated command resolves to the intended package manager in a new login shell, its regression test passes, and no duplicate path precedence is accidental.

**Rollback:** restore the Brewfile entry, run its reviewed Homebrew install command, remove the Nix package from the module, switch back, and retain the still-installed Homebrew package until the rollback test has passed.

### Phase 4 - Move static dotfiles to Home Manager

Migrate files one domain at a time, initially using `home.file` or `xdg.configFile` with existing repository files as sources.
This preserves the current file formats and avoids simultaneously rewriting configuration semantics.

Suggested order:

1. Starship.
2. Sesh and Television.
3. WezTerm, Ghostty, and AeroSpace configuration after application-level smoke tests.
4. Git user configuration and hooks after signing, conditional include, and hook execution tests.
5. Fish configuration.
6. Tmux configuration and pinned plugin workflow.
7. Neovim configuration, excluding generated data and lockfiles.
8. Zsh configuration last, because it controls the path, Homebrew initialization, Oh My Zsh, secret loading, OrbStack, Bun, Go, pnpm, and project-specific behavior.

For each target or tightly coupled domain:

1. Verify the file is canonical in Git and contains no secret or machine-local content.
2. Declare it in a dedicated Home Manager module with `force = false` during the first activation.
3. Add the target to an explicit ownership map used by both Home Manager configuration and the repository verifier.
4. Update `.stow-local-ignore` so Stow will not attempt to own the target in future setups.
5. Confirm the existing target is a repository-owned Stow symlink before unlinking it.
   Back up a regular or foreign target instead of replacing it.
6. Activate Home Manager and confirm the target resolves into `/nix/store`.
7. Run the domain's real consumer test in a fresh process.
8. Update `setup.sh`, `uninstall.sh`, `verify.sh`, `scripts/lib/managed-links.sh`, lifecycle tests, and README ownership documentation together.

Do not use `stow --adopt` for this cutover.
Do not let Home Manager replace a Stow link implicitly.
The migration helper must refuse a target that is not an expected repository-owned link.

**Exit criterion:** every migrated target has one documented owner, verifies as a Home Manager target, and is accepted by its real application.

**Rollback:** disable the relevant Home Manager declaration, switch, restore the recorded Stow link only if its target is still repository-owned, remove its Stow ignore rule, and run the original verifier.

### Phase 5 - Convert selected configuration to native modules

Only after a file has been stable under Home Manager links should it be rewritten into native modules where that provides a clear benefit.

Candidates include `programs.git`, `programs.starship`, `programs.zoxide`, `programs.fzf`, `programs.tmux`, `programs.zsh`, and `programs.fish`.

For each conversion, compare the rendered configuration to the previous file-based version and preserve:

- Git SSH signing, the Ksyos conditional include, custom hooks, and `gh` credential helper behavior.
- Current shell path ordering and all guarded optional integrations.
- The existing tmux and Neovim reviewed-lock workflows.
- `.local` override behavior.

Treat converting the shell configuration as a separate project with an explicit startup-performance and behavior acceptance suite.

**Exit criterion:** native modules reduce duplication or improve validation without removing a required customization.

### Phase 6 - Optional later macOS and Homebrew declaration

After user packages and dotfiles are proven stable, decide separately whether to:

- Express safe `defaults` values through nix-darwin while retaining imperative handling for display, NVRAM, launchctl, power, and software-update operations.
- Use nix-darwin's Homebrew integration or `nix-homebrew` to declare retained Homebrew packages.
- Keep the existing Brewfiles as the authoritative GUI and service manifest indefinitely.
- Add a second host only after the modules have been proven on this machine.

This phase is intentionally optional.
Declarative dotfiles do not require an all-Nix macOS system.

## Validation and operational policy

### Required checks for every adoption change

1. Repository status is known before mutation and before validation.
2. Shell and Nix files are formatted and statically checked.
3. `nix flake check` passes.
4. The exact host configuration evaluates and builds before activation.
5. `./verify.sh` recognizes both remaining Stow targets and migrated Home Manager targets.
6. Existing Bun, lifecycle safety, and tmux binding tests pass.
7. The changed application's real smoke test passes in a fresh process.
8. `type -a` confirms intentional command ownership where a Nix and Homebrew package share a binary name.

The verifier should report target ownership as `stow`, `home-manager`, `manual`, or `unmanaged`, rather than assuming every configuration link resolves to the repository checkout.

Add regression tests for unsafe ownership transitions: a regular file, a foreign symlink, an existing Nix-store link, a stale Stow link, and an activation failure caused by a conflict.

### Update policy

- Commit `flake.lock` and treat it as the reproducibility boundary.
- Update inputs deliberately in a dedicated change rather than during unrelated dotfile work.
- Review the lock diff, run the complete validation suite, activate once locally, and retain the prior generation for rollback.
- Do not enable unattended flake updates or automatic garbage collection.
- Run garbage collection only after the new configuration has been accepted and after inspecting generations and roots.

### Completion definition

The initial adoption is complete when:

- The Nix daemon, nix-darwin, and Home Manager are installed and pinned through the repository flake.
- The current Apple Silicon host rebuilds successfully from a fresh login shell.
- At least one useful CLI cohort and several low-risk static dotfile domains are Nix-owned.
- All remaining files and packages have an explicit owner and a recorded rationale.
- `setup.sh`, `uninstall.sh`, `verify.sh`, tests, and README accurately describe mixed Stow/Home Manager ownership.
- The previous Darwin generation, Homebrew manifest, and Stow rollback path have been tested.

## Main risks and controls

| Risk | Control |
| --- | --- |
| Stow and Home Manager overwrite the same file | Per-target ownership map, `force = false`, explicit symlink checks, and one-domain cutovers. |
| Homebrew and Nix supply different binaries | Migrate package cohorts, test command provenance, and change `PATH` only deliberately. |
| Secret exposure through the Nix Store | Never materialize secrets in Home Manager files or Nix expressions. |
| macOS update or installer incompatibility | Confirm current installer support before mutation and retain the official uninstall path. |
| Nix package gap or behavior mismatch | Retain Homebrew ownership and document the exception rather than forcing replacement. |
| Existing tool startup behavior changes | Keep raw configuration files first; convert to native modules only after behavior-based tests. |
| Irrecoverable cleanup | Do not run `brew cleanup`, `nix-collect-garbage`, or generation deletion until acceptance and a successful rollback rehearsal. |

## References

- [Nix installation on macOS](https://nix.dev/manual/nix/stable/installation/)
- [Nix flakes](https://nix.dev/concepts/flakes.html)
- [nix-darwin README](https://github.com/nix-darwin/nix-darwin/blob/master/README.md)
- [Home Manager manual - flakes](https://nix-community.github.io/home-manager/index.xhtml#ch-nix-flakes)
