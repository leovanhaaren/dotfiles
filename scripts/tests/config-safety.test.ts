import { describe, expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const root = join(import.meta.dir, "../..");
const read = (path: string) => readFileSync(join(root, path), "utf8");

describe("security-sensitive configuration", () => {
  test("Television hides opaque picker tokens while actions can use them", () => {
    const cable = read(".config/television/cable/sesh.toml");
    expect(cable).not.toContain("sh -c");
    expect(cable).toContain('display = "{strip_ansi|split:\\t:0}"');
    expect(cable).toContain("sesh-picker preview '{split:\\t:1}'");
    expect(cable).toContain("sesh-picker connect '{split:\\t:1}' --apply");
  });

  test("worktree helpers use Worktrunk without installing dependencies", () => {
    const functions = read(".functions");
    const gwao = functions.match(/gwao\(\) \{[\s\S]*?\n\}/)?.[0] ?? "";
    expect(gwao).toContain("wt switch");
    expect(gwao).not.toContain("npm install");

    const prWorktree = read(".config/gh-dash/pr-worktree.sh");
    expect(prWorktree).toContain('wt -C "$repo_path" switch');
    expect(prWorktree).not.toContain("git worktree");
  });

  test("default setup does not adopt conflicting files", () => {
    const setup = read("setup.sh");
    const defaultFlags = setup.match(/STOW_FLAGS=\(([^\n]+)\)/)?.[1] ?? "";
    expect(defaultFlags).not.toContain("--adopt");
    expect(setup).toContain('[ "$ADOPT" = true ] && STOW_FLAGS+=(--adopt)');
  });

  test("privileged migration drops privileges for Homebrew execution", () => {
    const migration = read("scripts/homebrew-ssd.sh");
    expect(migration).toContain("run_as_brew_user");
    expect(migration).toContain('/usr/bin/sudo -u "$BREW_USER"');
    expect(migration).not.toMatch(/^\s*"\/Volumes\/\$VOLUME_NAME\/bin\/brew"/m);
    expect(migration).not.toContain("brew doctor || true");
    expect(migration).not.toContain("/tmp/homebrew");
    expect(migration).toContain("backup_persistence");
    expect(migration).toContain("restore_persistence");
    expect(migration).toContain("Existing Homebrew volume is not empty");
  });

  test("provision mode never copies or overwrites an existing Homebrew", () => {
    const migration = read("scripts/homebrew-ssd.sh");
    // Copy and backup only happen in migration mode.
    expect(migration).toMatch(/if \[ "\$PROVISION" = false \]; then\n\s*log_info "Copying Homebrew/);
    // Provisioning on top of an internal-disk install must abort.
    expect(migration).toContain("migrate it by running without --provision");
    // Validation is skipped when no brew binary exists yet.
    expect(migration).toContain('[ "$DRY_RUN" = false ] && [ -x "$MOUNT_POINT/bin/brew" ]');
  });

  test("bootstrap code is explicit and pinned", () => {
    expect(read("scripts/brew.sh")).not.toContain("curl");
    expect(read(".config/nvim/lua/config/lazy.lua")).toContain("lazy_commit");
    expect(read(".config/nvim/lua/config/lazy.lua")).toContain('verifier, "verify", "--allow-missing"');
    expect(read(".gitignore")).toContain("/.config/nvim/lazy-lock.json");
    expect(read("scripts/lib/managed-links.sh")).not.toContain("nvim/lazy-lock.json");
    expect(read("bin/nvim-plugins")).toContain('${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json');
    expect(read("bin/nvim-plugins")).toContain("--untracked-files=all");
    expect(read("bin/tmux-plugins")).toContain("--untracked-files=all");
    expect(read(".tmux.conf")).toContain("tmux-plugins verify");
    expect(read("tmux/plugins.lock")).toMatch(/tpm\thttps:\/\/github\.com\/tmux-plugins\/tpm\.git\t[0-9a-f]{40}/);
  });

  test("system updates require a separate opt-in", () => {
    const mac = read("scripts/mac.sh");
    expect(mac).toContain('if [ "$INSTALL_SYSTEM_UPDATES" = true ]');
    expect(mac).toContain("--install-system-updates");
  });
});

describe("lifecycle correctness", () => {
  test("verification accepts folded Stow paths but rejects wrong targets", () => {
    const verify = read("verify.sh");
    expect(verify).toContain('[ "$resolved" = "$expected" ]');
    expect(verify).toContain('log_error "$description: resolves to');
    expect(verify).toContain("managed_manual_links");
    expect(verify).toContain("check_stow_state");
  });

  test("uninstall checks link ownership", () => {
    const uninstall = read("uninstall.sh");
    expect(uninstall).toContain('if [ "$resolved" != "$source" ]');
    expect(uninstall).toContain("Not owned by this repository, leaving untouched");
  });

  test("Brewfile package names do not begin with whitespace", () => {
    expect(read("homebrew/Brewfile.base")).not.toMatch(/^go "\s/m);
  });

  test("Brewfile trusts only explicitly selected third-party packages", () => {
    const brewfiles = `${read("homebrew/Brewfile.base")}\n${read("homebrew/Brewfile.work")}`;
    const trustedPackages = [
      'brew "felixkratz/formulae/borders", trusted: true',
      'brew "rjyo/moshi/moshi-hook", trusted: true',
      'brew "agavra/tap/tuicr", trusted: true',
      'brew "gromgit/brewtils/taproom", trusted: true',
      'brew "modem-dev/tap/hunk", trusted: true',
      'brew "protonpass/tap/pass-cli", trusted: true',
      'brew "datadog-labs/pack/pup", trusted: true',
      'cask "vishvavariya/notchy/notchy", trusted: true',
      'cask "nguyenphutrong/tap/quotio", trusted: true',
      'cask "nikitabobko/tap/aerospace", trusted: true',
      'cask "ovh/tap/ovhcloud-cli", trusted: true',
    ];

    for (const packageEntry of trustedPackages) {
      expect(brewfiles).toContain(packageEntry);
    }
    expect(brewfiles).not.toMatch(/^tap .*trusted: true/m);
  });

  test("Zsh works without Oh My Zsh: own compinit, Homebrew plugins sourced", () => {
    const brewfile = read("homebrew/Brewfile.base");
    const zshrc = read(".zshrc");

    expect(brewfile).toContain('brew "zsh-autosuggestions"');
    expect(brewfile).toContain('brew "zsh-syntax-highlighting"');
    expect(zshrc).toContain("compinit");
    expect(zshrc).not.toContain("oh-my-zsh.sh");
    expect(zshrc).toContain("share/zsh-autosuggestions/zsh-autosuggestions.zsh");
    expect(zshrc).toContain("share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh");
  });

  test("managed application configuration is intentional and reachable", () => {
    expect(existsSync(join(root, ".config/cmux/cmux.json"))).toBeFalse();
    expect(read(".config/aerospace/aerospace.toml")).toContain("alt-a = 'workspace a'");
  });
});
