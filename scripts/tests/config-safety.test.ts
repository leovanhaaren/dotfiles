import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const root = join(import.meta.dir, "../..");
const read = (path: string) => readFileSync(join(root, path), "utf8");

describe("security-sensitive configuration", () => {
  test("Television actions receive only opaque picker tokens", () => {
    const cable = read(".config/television/cable/sesh.toml");
    expect(cable).not.toContain("sh -c");
    expect(cable).toContain("sesh-picker preview '{split:\\t:1}'");
    expect(cable).toContain("sesh-picker connect '{split:\\t:1}' --apply");
  });

  test("remote worktree checkout does not install dependencies", () => {
    const functions = read(".functions");
    const gwao = functions.match(/gwao\(\) \{[\s\S]*?\n\}/)?.[0] ?? "";
    expect(gwao).toContain("wt switch");
    expect(gwao).not.toContain("npm install");
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
  });

  test("system updates require a separate opt-in", () => {
    const mac = read("scripts/mac.sh");
    expect(mac).toContain('if [ "$INSTALL_SYSTEM_UPDATES" = true ]');
    expect(mac).toContain("--install-system-updates");
  });
});

describe("lifecycle correctness", () => {
  test("verification treats wrong required links as errors", () => {
    const verify = read("verify.sh");
    expect(verify).toContain('log_error "$description: exists but is not a symlink');
    expect(verify).toContain("managed_manual_links");
  });

  test("uninstall checks link ownership", () => {
    const uninstall = read("uninstall.sh");
    expect(uninstall).toContain('if [ "$resolved" != "$source" ]');
    expect(uninstall).toContain("Not owned by this repository, leaving untouched");
  });

  test("Brewfile package names do not begin with whitespace", () => {
    expect(read("homebrew/Brewfile.base")).not.toMatch(/^go "\s/m);
  });
});
