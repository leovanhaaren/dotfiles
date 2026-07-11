import { describe, expect, test } from "bun:test";
import {
  decodeRecord,
  encodeRecord,
  parseClaudeMetadata,
  parseCodexMetadata,
  parsePiMetadata,
  resumeInvocation,
  type SessionRecord,
} from "../../bin/agent-sessions";

const modified = Date.parse("2026-07-10T12:00:00Z");

describe("session metadata", () => {
  test("Claude prefers generated title and keeps project metadata", () => {
    const record = parseClaudeMetadata("/sessions/claude-id.jsonl", [
      { type: "user", sessionId: "claude-id", cwd: "/work/alpha", timestamp: "2026-07-10T10:00:00Z", message: { role: "user", content: "Fallback prompt" } },
      { type: "ai-title", sessionId: "claude-id", aiTitle: "Generated title" },
    ], modified);

    expect(record).toMatchObject({ tool: "claude", id: "claude-id", cwd: "/work/alpha", title: "Generated title", updated: modified });
  });

  test("Codex uses session index title and update timestamp", () => {
    const indexedUpdate = Date.parse("2026-07-10T11:00:00Z");
    const record = parseCodexMetadata("/sessions/codex.jsonl", [
      { type: "session_meta", timestamp: "2026-07-10T09:00:00Z", payload: { id: "codex-id", cwd: "/work/beta" } },
      { type: "event_msg", payload: { type: "user_message", message: "Fallback prompt" } },
    ], modified, new Map([["codex-id", { title: "Indexed title", updated: indexedUpdate }]]));

    expect(record).toMatchObject({ tool: "codex", title: "Indexed title", updated: indexedUpdate });
  });

  test("Pi prefers latest explicit session name", () => {
    const record = parsePiMetadata("/sessions/pi.jsonl", [
      { type: "session", id: "pi-id", cwd: "/work/gamma", timestamp: "2026-07-10T08:00:00Z" },
      { type: "message", message: { role: "user", content: "Fallback prompt" } },
      { type: "session_info", name: "First name" },
      { type: "session_info", name: "Current name" },
    ], modified);

    expect(record).toMatchObject({ tool: "pi", id: "pi-id", cwd: "/work/gamma", title: "Current name" });
  });
});

describe("picker selection", () => {
  const record: SessionRecord = {
    version: 1,
    tool: "pi",
    id: "session-id",
    title: "Title with ' quote",
    cwd: "/work/project",
    path: "/sessions/pi.jsonl",
    created: modified,
    updated: modified,
  };

  test("opaque token round-trips without exposing shell-sensitive fields", () => {
    const token = encodeRecord(record);
    expect(token).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(decodeRecord(`display text\t${token}`)).toEqual(record);
  });

  test.each([
    ["claude", ["claude", "--resume", "session-id"]],
    ["codex", ["codex", "resume", "session-id", "-C", "/work/project"]],
    ["opencode", ["opencode", "--session", "session-id"]],
    ["pi", ["pi", "--session", "/sessions/pi.jsonl"]],
  ] as const)("builds %s resume command", (tool, command) => {
    expect(resumeInvocation({ ...record, tool })).toEqual({ command: [...command], cwd: "/work/project" });
  });

  test("rejects a token with an unknown tool", () => {
    const token = Buffer.from(JSON.stringify({ ...record, tool: "unknown" })).toString("base64url");
    expect(() => decodeRecord(token)).toThrow("Invalid session selection");
  });
});
