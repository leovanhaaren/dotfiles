import { afterEach, describe, expect, test } from "bun:test";
import { chmodSync, lstatSync, mkdtempSync, mkdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const root = join(import.meta.dir, "../..");
const script = join(root, "bin/create-github-ssh-key");
const temporaryDirectories: string[] = [];

const makeTemporaryDirectory = () => {
  const directory = mkdtempSync(join(tmpdir(), "create-github-ssh-key-"));
  temporaryDirectories.push(directory);
  return directory;
};

const writeExecutable = (path: string, content: string) => {
  writeFileSync(path, content);
  chmodSync(path, 0o755);
};

afterEach(() => {
  for (const directory of temporaryDirectories.splice(0)) {
    rmSync(directory, { recursive: true, force: true });
  }
});

describe("create-github-ssh-key", () => {
  test("defaults to a true dry run", async () => {
    const home = makeTemporaryDirectory();
    const result = Bun.spawnSync([script, "--title", "Dry-run key"], {
      env: { ...process.env, HOME: home },
      stdout: "pipe",
      stderr: "pipe",
    });

    expect(result.exitCode).toBe(0);
    expect(result.stdout.toString()).toContain("DRY RUN");
    expect(result.stdout.toString()).toContain("Dry-run key");
    expect(result.stdout.toString()).toContain("no local files, vault items, GitHub settings, or local configuration were changed");
    expect(readFileSync(script, "utf8")).toContain("if [[ \"$APPLY\" != true ]]");
  });

  test("plans a separate signing key and Git configuration", () => {
    const home = makeTemporaryDirectory();
    const result = Bun.spawnSync([script, "--type", "signing", "--title", "Signing key"], {
      env: { ...process.env, HOME: home },
      stdout: "pipe",
      stderr: "pipe",
    });

    expect(result.exitCode).toBe(0);
    expect(result.stdout.toString()).toContain("Key type:          signing");
    expect(result.stdout.toString()).toContain(`${home}/.ssh/id_leo_ksyos_signing.pub`);
    expect(result.stdout.toString()).toContain(`${home}/.config/git/ksyos.gitconfig`);
    expect(result.stdout.toString()).not.toContain("GitHub SSH host");
  });

  test("rejects a title that conflicts with the selected key purpose", () => {
    const result = Bun.spawnSync([script, "--type", "signing", "--title", "Fixture authentication key"], {
      stdout: "pipe",
      stderr: "pipe",
    });

    expect(result.exitCode).toBe(2);
    expect(result.stderr.toString()).toContain("title conflicts with the selected key type");
  });

  test("rejects resume without explicit apply", () => {
    const result = Bun.spawnSync([script, "--resume"], {
      stdout: "pipe",
      stderr: "pipe",
    });

    expect(result.exitCode).toBe(2);
    expect(result.stderr.toString()).toContain("--resume is only valid with --apply");
  });

  test("rejects path escapes before invoking apply operations", () => {
    const result = Bun.spawnSync(
      [script, "--public-key", "/safe/id.pub\\nProxyCommand malicious-command"],
      { stdout: "pipe", stderr: "pipe" },
    );

    expect(result.exitCode).toBe(2);
    expect(result.stderr.toString()).toContain("double quotes or backslashes are not supported");
  });

  test("applies authentication and signing workflows safely", async () => {
    const fixture = makeTemporaryDirectory();
    const home = join(fixture, "home");
    const mockBin = join(fixture, "bin");
    const sshDirectory = join(home, ".ssh");
    const agentDirectory = join(home, "agent");
    const agentSocket = join(agentDirectory, "agent.sock");
    const publicKey = join(sshDirectory, "id_leo_ksyos.pub");
    const signingPublicKey = join(sshDirectory, "id_leo_ksyos_signing.pub");
    const config = join(sshDirectory, "config");
    const configSource = join(fixture, "repo", "ssh", "config.macos");
    const gitConfig = join(fixture, "repo", "git", "ksyos.gitconfig");
    const signingProgram = join(mockBin, "op-ssh-sign");
    const commandLog = join(fixture, "commands.log");
    const generatedPrivateKey = join(fixture, "generated-key");

    mkdirSync(mockBin, { recursive: true });
    mkdirSync(sshDirectory, { recursive: true });
    mkdirSync(agentDirectory, { recursive: true });
    mkdirSync(join(fixture, "repo", "ssh"), { recursive: true });
    mkdirSync(join(fixture, "repo", "git"), { recursive: true });
    writeFileSync(gitConfig, "[user]\n\tname = Fixture User\n\tsigningkey = ~/.ssh/old-signing-key.pub\n");
    writeFileSync(
      configSource,
      `Host github.com-ksyos\n  HostName github.com\n  User git\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/id_leo_ksyos\n\nHost retained.example\n  ProxyJump jump.example\n`,
    );
    symlinkSync(configSource, config);

    const keygen = Bun.spawnSync(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", "fixture", "-f", generatedPrivateKey]);
    expect(keygen.exitCode).toBe(0);
    const signingAgentStart = Bun.spawnSync(["/usr/bin/ssh-agent", "-s"]);
    expect(signingAgentStart.exitCode).toBe(0);
    const signingAgentOutput = signingAgentStart.stdout.toString();
    const signingAgentSocket = signingAgentOutput.match(/SSH_AUTH_SOCK=([^;]+)/)?.[1] ?? "";
    const signingAgentPid = signingAgentOutput.match(/SSH_AGENT_PID=([0-9]+)/)?.[1] ?? "";
    expect(signingAgentSocket).not.toBe("");
    expect(signingAgentPid).not.toBe("");
    const signingAgentEnvironment = { ...process.env, SSH_AUTH_SOCK: signingAgentSocket, SSH_AGENT_PID: signingAgentPid };
    const addSigningKey = Bun.spawnSync(["/usr/bin/ssh-add", generatedPrivateKey], {
      env: signingAgentEnvironment,
      stdout: "pipe",
      stderr: "pipe",
    });
    expect(addSigningKey.exitCode).toBe(0);

    writeExecutable(
      join(mockBin, "gh"),
      `#!/bin/bash
set -e
printf 'gh %s\\n' "$*" >> "$MOCK_COMMAND_LOG"
if [[ "$1 $2" == "auth status" ]]; then
  printf '%s\\n' '{"hosts":{"github.com":[{"state":"success","active":true,"host":"github.com","login":"leo-ksyos","scopes":"repo, admin:public_key","gitProtocol":"ssh"}]}}'
elif [[ "$1 $2" == "auth token" ]]; then
  printf '%s\\n' 'fixture-token'
elif [[ "$1 $2" == "api user" ]]; then
  printf '%s\\n' 'leo-ksyos'
elif [[ "$1 $2" == "api --include" ]]; then
  printf 'X-OAuth-Scopes: %s\\n\\n{}\\n' "\${MOCK_GH_SCOPES:-admin:public_key, admin:ssh_signing_key}"
elif [[ "$1 $2" == "api user/keys?per_page=1" ]]; then
  printf '%s\\n' '[]'
elif [[ "$1 $2" == "api user/keys" ]]; then
  printf '%s\\n' '[]'
elif [[ "$1 $2" == "api user/ssh_signing_keys?per_page=1" ]]; then
  printf '%s\\n' '[]'
elif [[ "$1 $2" == "api user/ssh_signing_keys" ]]; then
  printf '%s\\n' '[]'
elif [[ "$1 $2" == "api users/leo-ksyos/keys" ]]; then
  printf '%s\\n' "\${MOCK_AUTHENTICATION_KEYS:-}"
elif [[ "$1 $2" == "api users/leo-ksyos/ssh_signing_keys" ]]; then
  printf '%s\\n' "\${MOCK_SIGNING_KEYS:-}"
elif [[ "$1 $2" == "ssh-key add" ]]; then
  [[ -s "$3" ]]
else
  echo "unexpected gh invocation: $*" >&2
  exit 1
fi
`,
    );

    writeExecutable(
      join(mockBin, "op"),
      `#!/bin/bash
set -e
printf 'op %s\\n' "$*" >> "$MOCK_COMMAND_LOG"
if [[ "$1 $2" == "vault get" ]]; then
  printf '%s\\n' '{"id":"vault"}'
elif [[ "$1 $2" == "item list" ]]; then
  if [[ -n "\${MOCK_EXISTING_ITEM_TITLE:-}" ]]; then
    printf '[{"id":"existing-item","title":"%s"}]\\n' "$MOCK_EXISTING_ITEM_TITLE"
  else
    printf '%s\\n' '[]'
  fi
elif [[ "$1 $2" == "item create" ]]; then
  printf '%s\\n' '{"id":"created-item"}'
elif [[ "$1" == "read" ]]; then
  output=""
  reference=""
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --out-file) output="$2"; shift 2 ;;
      *) reference="$1"; shift ;;
    esac
  done
  if [[ "$reference" == *"public key" ]]; then
    cp "$MOCK_PRIVATE_KEY.pub" "$output"
  elif [[ "$reference" == *"private key"* ]]; then
    cat "$MOCK_PRIVATE_KEY"
  else
    exit 1
  fi
else
  echo "unexpected op invocation: $*" >&2
  exit 1
fi
`,
    );

    writeExecutable(
      join(mockBin, "pass-cli"),
      `#!/bin/bash
set -e
printf 'pass-cli %s\\n' "$*" >> "$MOCK_COMMAND_LOG"
if [[ "$1" == "test" ]]; then
  exit 0
elif [[ "$1 $2" == "vault list" ]]; then
  printf '%s\\n' '- [vault-id]: SSH'
elif [[ "$1 $2" == "item list" ]]; then
  if [[ -n "\${MOCK_EXISTING_ITEM_TITLE:-}" ]]; then
    printf '{"items":[{"id":"existing-proton","title":"%s"}]}\\n' "$MOCK_EXISTING_ITEM_TITLE"
  else
    printf '%s\\n' '{"items":[]}'
  fi
elif [[ "$1 $2 $3 $4" == "item create ssh-key import" ]]; then
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--from-private-key" ]]; then
      cat "$2" >/dev/null
      exit 0
    fi
    shift
  done
  exit 1
else
  echo "unexpected pass-cli invocation: $*" >&2
  exit 1
fi
`,
    );

    writeExecutable(
      join(mockBin, "ssh"),
      `#!/bin/bash
printf '%s\\n' "Hi leo-ksyos! You've successfully authenticated, but GitHub does not provide shell access."
exit 1
`,
    );
    writeExecutable(
      signingProgram,
      `#!/bin/bash
printf 'signing-program %s\\n' "$*" >> "$MOCK_COMMAND_LOG"
exec /usr/bin/ssh-keygen "$@"
`,
    );

    const server = Bun.listen({
      unix: agentSocket,
      socket: {
        data() {},
      },
    });

    const applyArguments = [
      script,
      "--apply",
      "--title",
      "Fixture authentication key",
      "--public-key",
      publicKey,
      "--ssh-config",
      config,
      "--identity-agent",
      agentSocket,
    ];
    const applyEnvironment = {
      ...process.env,
      HOME: home,
      PATH: `${mockBin}:${process.env.PATH}`,
      MOCK_COMMAND_LOG: commandLog,
      MOCK_PRIVATE_KEY: generatedPrivateKey,
      SSH_AUTH_SOCK: signingAgentSocket,
      SSH_AGENT_PID: signingAgentPid,
    };

    try {
      const result = Bun.spawnSync(applyArguments, {
        env: applyEnvironment,
        stdout: "pipe",
        stderr: "pipe",
      });

      expect(result.exitCode).toBe(0);
      expect(result.stderr.toString()).toBe("");
      expect(result.stdout.toString()).toContain("Done. The authentication private key is stored in 1Password and Proton Pass");
      expect(readFileSync(publicKey, "utf8")).toBe(readFileSync(`${generatedPrivateKey}.pub`, "utf8"));

      expect(lstatSync(config).isSymbolicLink()).toBeTrue();
      const updatedConfig = readFileSync(configSource, "utf8");
      expect(updatedConfig).toContain('IdentityAgent "~/agent/agent.sock"');
      expect(updatedConfig).toContain('IdentityFile "~/.ssh/id_leo_ksyos.pub"');
      expect(updatedConfig).not.toContain(home);
      expect(updatedConfig).toContain("IdentitiesOnly yes");
      expect(updatedConfig).not.toContain("AddKeysToAgent");
      expect(updatedConfig).not.toContain("UseKeychain");
      expect(updatedConfig).toContain("Host retained.example\n  ProxyJump jump.example");

      const secondResult = Bun.spawnSync(applyArguments, {
        env: applyEnvironment,
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(secondResult.exitCode).toBe(0);
      expect(secondResult.stdout.toString()).not.toContain("Updated SSH host");
      expect(readFileSync(configSource, "utf8")).toBe(updatedConfig);
      expect(lstatSync(config).isSymbolicLink()).toBeTrue();

      const itemCreatesBeforeLockTest = readFileSync(commandLog, "utf8").match(/op item create/g)?.length ?? 0;
      const lockDirectory = join(sshDirectory, ".create-github-ssh-key.lock");
      mkdirSync(lockDirectory);
      const lockedArguments = [...applyArguments];
      lockedArguments[lockedArguments.indexOf(publicKey)] = join(fixture, "other", "different-key.pub");
      const lockedResult = Bun.spawnSync(lockedArguments, {
        env: applyEnvironment,
        stdout: "pipe",
        stderr: "pipe",
      });
      rmSync(lockDirectory, { recursive: true });
      expect(lockedResult.exitCode).toBe(1);
      expect(lockedResult.stderr.toString()).toContain("another create-github-ssh-key apply appears to be running");
      expect(readFileSync(commandLog, "utf8").match(/op item create/g)?.length ?? 0).toBe(itemCreatesBeforeLockTest);

      const danglingConfig = join(sshDirectory, "dangling-config");
      symlinkSync(join(fixture, "missing-config"), danglingConfig);
      const danglingArguments = [...applyArguments];
      danglingArguments[danglingArguments.indexOf(config)] = danglingConfig;
      const danglingResult = Bun.spawnSync(danglingArguments, {
        env: applyEnvironment,
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(danglingResult.exitCode).toBe(1);
      expect(danglingResult.stderr.toString()).toContain("configuration is a dangling symbolic link");
      expect(readFileSync(commandLog, "utf8").match(/op item create/g)?.length ?? 0).toBe(itemCreatesBeforeLockTest);

      const readOnlyScopeResult = Bun.spawnSync(applyArguments, {
        env: { ...applyEnvironment, MOCK_GH_SCOPES: "read:public_key" },
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(readOnlyScopeResult.exitCode).toBe(1);
      expect(readOnlyScopeResult.stderr.toString()).toContain("lack the admin:public_key write scope");
      expect(readFileSync(commandLog, "utf8").match(/op item create/g)?.length ?? 0).toBe(itemCreatesBeforeLockTest);

      const fixturePublicKey = readFileSync(`${generatedPrivateKey}.pub`, "utf8").trim().split(/\s+/).slice(0, 2).join(" ");
      const crossPurposeResult = Bun.spawnSync(
        [
          script,
          "--apply",
          "--resume",
          "--type",
          "signing",
          "--title",
          "Legacy signing key",
          "--public-key",
          signingPublicKey,
          "--git-config",
          gitConfig,
          "--signing-program",
          signingProgram,
        ],
        {
          env: {
            ...applyEnvironment,
            MOCK_EXISTING_ITEM_TITLE: "Legacy signing key",
            MOCK_AUTHENTICATION_KEYS: fixturePublicKey,
          },
          stdout: "pipe",
          stderr: "pipe",
        },
      );
      expect(crossPurposeResult.exitCode).toBe(1);
      expect(crossPurposeResult.stderr.toString()).toContain("already registered for the opposite GitHub key purpose");

      const signingResult = Bun.spawnSync(
        [
          script,
          "--apply",
          "--type",
          "signing",
          "--title",
          "Fixture signing key",
          "--public-key",
          signingPublicKey,
          "--git-config",
          gitConfig,
          "--signing-program",
          signingProgram,
        ],
        {
          env: applyEnvironment,
          stdout: "pipe",
          stderr: "pipe",
        },
      );
      expect(signingResult.exitCode).toBe(0);
      expect(signingResult.stderr.toString()).toBe("");
      expect(signingResult.stdout.toString()).toContain("Verified a signed test commit");
      expect(signingResult.stdout.toString()).toContain("Done. The signing private key is stored");
      expect(readFileSync(signingPublicKey, "utf8")).toBe(readFileSync(`${generatedPrivateKey}.pub`, "utf8"));
      expect(Bun.spawnSync(["/usr/bin/git", "config", "--file", gitConfig, "--get", "user.signingkey"]).stdout.toString().trim()).toBe(readFileSync(`${generatedPrivateKey}.pub`, "utf8").trim().split(/\s+/).slice(0, 2).join(" "));
      expect(Bun.spawnSync(["/usr/bin/git", "config", "--file", gitConfig, "--get", "gpg.format"]).stdout.toString().trim()).toBe("ssh");
      expect(Bun.spawnSync(["/usr/bin/git", "config", "--file", gitConfig, "--get", "gpg.ssh.program"]).stdout.toString().trim()).toBe(signingProgram);

      const failingGitConfig = join(fixture, "repo", "git", "failing.gitconfig");
      const originalFailingGitConfig = "[user]\n\tname = Unchanged User\n\tsigningkey = old-key\n";
      writeFileSync(failingGitConfig, originalFailingGitConfig);
      const failingSigningResult = Bun.spawnSync(
        [
          script,
          "--apply",
          "--type",
          "signing",
          "--title",
          "Fixture signing failure",
          "--public-key",
          join(sshDirectory, "failing-signing-key.pub"),
          "--git-config",
          failingGitConfig,
          "--signing-program",
          "/usr/bin/false",
        ],
        {
          env: applyEnvironment,
          stdout: "pipe",
          stderr: "pipe",
        },
      );
      expect(failingSigningResult.exitCode).toBe(1);
      expect(failingSigningResult.stderr.toString()).toContain("could not create a signed test commit");
      expect(readFileSync(failingGitConfig, "utf8")).toBe(originalFailingGitConfig);

      const calls = readFileSync(commandLog, "utf8");
      expect(calls).toContain("op item create");
      expect(calls).toContain("pass-cli item create ssh-key import");
      expect(calls).toContain("gh ssh-key add");
      expect(calls).toContain("--type signing");
      expect(calls).toContain("signing-program -Y sign");
      expect(calls).toContain("signing-program -Y verify");
    } finally {
      server.stop(true);
      Bun.spawnSync(["/usr/bin/ssh-agent", "-k"], {
        env: signingAgentEnvironment,
        stdout: "pipe",
        stderr: "pipe",
      });
    }
  });
});
