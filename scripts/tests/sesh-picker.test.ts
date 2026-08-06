import { describe, expect, test } from "bun:test";
import {
  connectInvocation,
  decodeRecord,
  encodeRecord,
  killInvocation,
  parseWorktreePaths,
  pickerLine,
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

  test("keep display control characters out of the Television field separator", () => {
    const line = pickerLine({ ...record, display: "directory:\tunsafe\nname" });
    expect(line.split("\t")).toHaveLength(2);
    expect(line.split("\t")[0]).toBe("directory: unsafe name");
  });

  test("pass selections as one argv element", () => {
    expect(previewInvocation(record)).toEqual(["sesh", "preview", "--", hostilePath]);
    expect(connectInvocation(record)).toEqual(["sesh", "connect", "--", hostilePath]);
    expect(killInvocation(record)).toEqual(["tmux", "kill-session", "-t", hostilePath]);
  });

  test("reject malformed records", () => {
    const token = Buffer.from(JSON.stringify({ ...record, kind: "shell" })).toString("base64url");
    expect(() => decodeRecord(token)).toThrow("Invalid picker selection");

    const invalidHerdr = Buffer.from(JSON.stringify({ ...record, kind: "herdr", value: "--help" })).toString("base64url");
    expect(() => decodeRecord(invalidHerdr)).toThrow("Invalid picker selection");
  });

  test("keeps informational rows non-actionable", () => {
    const info: PickerRecord = {
      version: 1,
      kind: "info",
      display: "No active tmux sessions",
      value: "Herdr does not use tmux.",
    };

    expect(decodeRecord(encodeRecord(info))).toEqual(info);
    expect(previewInvocation(info)).toBeUndefined();
    expect(connectInvocation(info)).toBeUndefined();
    expect(killInvocation(info)).toBeUndefined();
  });

  test("does not expose a kill action for Herdr workspaces", () => {
    expect(killInvocation({ ...record, kind: "herdr", value: "12" })).toBeUndefined();
  });

  test("extracts valid Worktrunk paths from dirty JSON records", () => {
    expect(parseWorktreePaths(JSON.stringify([
      { path: "/repo/one" },
      { path: "" },
      { missing: "path" },
      null,
      { path: "/repo/two" },
    ]))).toEqual(["/repo/one", "/repo/two"]);
    expect(parseWorktreePaths("not json")).toEqual([]);
  });
});
