import { describe, expect, test } from "bun:test";
import {
  connectInvocation,
  decodeRecord,
  encodeRecord,
  killInvocation,
  previewInvocation,
  type PickerRecord,
} from "../../bin/sesh-picker";

const hostilePath = "/Users/test/Downloads/review'; printf injected; #'";
const record: PickerRecord = {
  version: 1,
  kind: "sesh",
  display: `directory: ${hostilePath}`,
  value: hostilePath,
};

describe("opaque picker selections", () => {
  test("encode shell-sensitive values as inert token characters", () => {
    const token = encodeRecord(record);
    expect(token).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(token).not.toContain("printf");
    expect(decodeRecord(`display text\t${token}`)).toEqual(record);
  });

  test("pass selections as one argv element", () => {
    expect(previewInvocation(record)).toEqual(["sesh", "preview", hostilePath]);
    expect(connectInvocation(record)).toEqual(["sesh", "connect", hostilePath]);
    expect(killInvocation(record)).toEqual(["tmux", "kill-session", "-t", hostilePath]);
  });

  test("reject malformed records", () => {
    const token = Buffer.from(JSON.stringify({ ...record, kind: "shell" })).toString("base64url");
    expect(() => decodeRecord(token)).toThrow("Invalid picker selection");
  });

  test("does not expose a kill action for Herdr workspaces", () => {
    expect(killInvocation({ ...record, kind: "herdr", value: "12" })).toBeUndefined();
  });
});
