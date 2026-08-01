#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SANDBOX="$ROOT/.test-safety-$$"
cleanup() {
    rm -rf "$SANDBOX"
}
trap cleanup EXIT
mkdir -p "$SANDBOX/home" "$SANDBOX/fake-bin"

before=$(find "$SANDBOX/home" -mindepth 1 -print | LC_ALL=C sort)
HOME="$SANDBOX/home" "$ROOT/setup.sh" > "$SANDBOX/setup.log"
after=$(find "$SANDBOX/home" -mindepth 1 -print | LC_ALL=C sort)
[ "$before" = "$after" ] || { echo "setup default dry run wrote to HOME" >&2; exit 1; }
grep -q "DRY RUN MODE" "$SANDBOX/setup.log"

HOME="$SANDBOX/home" "$ROOT/uninstall.sh" > "$SANDBOX/uninstall.log"
after=$(find "$SANDBOX/home" -mindepth 1 -print | LC_ALL=C sort)
[ "$before" = "$after" ] || { echo "uninstall default dry run wrote to HOME" >&2; exit 1; }
grep -q "DRY RUN MODE" "$SANDBOX/uninstall.log"

"$ROOT/scripts/mac.sh" > "$SANDBOX/mac.log"
grep -q "DRY-RUN" "$SANDBOX/mac.log"

mkdir -p "$SANDBOX/helper/bin" "$SANDBOX/helper/vscode"
cp "$ROOT/bin/save-vscode-extensions" "$SANDBOX/helper/bin/"
printf 'existing.extension\n' > "$SANDBOX/helper/vscode/extensions.list"
cat > "$SANDBOX/fake-bin/code" <<'SCRIPT'
#!/usr/bin/env bash
printf 'z.extension\na.extension\n'
SCRIPT
chmod +x "$SANDBOX/fake-bin/code"
before=$(cat "$SANDBOX/helper/vscode/extensions.list")
PATH="$SANDBOX/fake-bin:$PATH" "$SANDBOX/helper/bin/save-vscode-extensions" > "$SANDBOX/vscode-dry.log"
[ "$before" = "$(cat "$SANDBOX/helper/vscode/extensions.list")" ] || { echo "VS Code helper dry run wrote output" >&2; exit 1; }
PATH="$SANDBOX/fake-bin:$PATH" "$SANDBOX/helper/bin/save-vscode-extensions" --apply >/dev/null
expected=$(printf 'a.extension\nz.extension')
actual=$(cat "$SANDBOX/helper/vscode/extensions.list")
[ "$actual" = "$expected" ] || { echo "VS Code helper did not write sorted extensions" >&2; exit 1; }

cat > "$SANDBOX/fake-bin/pi" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "$SANDBOX/fake-bin/pi"
if PATH="$SANDBOX/fake-bin:$PATH" zsh -dfc "source '$ROOT/.functions'; cd '$ROOT'; _generate_commit_msg" >/dev/null 2>&1; then
    echo "empty commit messages must fail" >&2
    exit 1
fi

echo "lifecycle safety checks passed"
