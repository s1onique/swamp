// AGPLv3 header — see FILE-LICENSE-TEMPLATE.md
import {
  stripAnsi,
  parseSummary,
  extractFailures,
} from "./parse_deno_test_result.ts";
import { assertEquals, assert } from "@std/assert";

Deno.test("stripAnsi: removes CSI sequences", () => {
  const input = "before\x1b[31mRED\x1b[0mafter";
  assertEquals(stripAnsi(input), "beforeREDafter");
});

Deno.test("stripAnsi: leaves non-CSI escapes alone", () => {
  const input = "x\x1b]0;title\x07y";
  assertEquals(stripAnsi(input), input);
});

Deno.test("stripAnsi: collapses standalone \\r", () => {
  const input = "line1\roverwrite\nline2";
  const out = stripAnsi(input);
  assert(out.includes("line2"));
});

Deno.test("parseSummary: ok summary no ignored", () => {
  const text = "ok | 50 passed | 0 failed (1s)";
  const r = parseSummary(text);
  assert(r);
  assertEquals(r.passed, 50);
  assertEquals(r.failed, 0);
  assertEquals(r.ignored, 0);
  assertEquals(r.duration, 1);
});

Deno.test("parseSummary: FAILED summary with steps and minutes", () => {
  const text = "FAILED | 12128 passed (214 steps) | 160 failed | 30 ignored (1 step) (1m40s)";
  const r = parseSummary(text);
  assert(r);
  assertEquals(r.passed, 12128);
  assertEquals(r.failed, 160);
  assertEquals(r.ignored, 30);
  assertEquals(r.duration, 100);
});

Deno.test("parseSummary: FAILED summary with ignored steps", () => {
  const text = "FAILED | 10 passed | 1 failed | 2 ignored (1 step) (5s)";
  const r = parseSummary(text);
  assert(r);
  assertEquals(r.passed, 10);
  assertEquals(r.failed, 1);
  assertEquals(r.ignored, 2);
  assertEquals(r.duration, 5);
});

Deno.test("parseSummary: rejects malformed", () => {
  assertEquals(parseSummary("this is not a summary"), null);
});

Deno.test("extractFailures: real Deno failure line shape", () => {
  const text = "./src/cli/repo_context_test.ts => requireInitializedRepo - returns context for initialized repo (json mode) ... FAILED (12ms)\nok | 1 passed | 0 failed (1s)\n";
  const fails = extractFailures(text);
  assertEquals(fails.length, 1);
  assertEquals(fails[0].test_file, "./src/cli/repo_context_test.ts");
  assertEquals(fails[0].test_name, "requireInitializedRepo - returns context for initialized repo (json mode)");
  assertEquals(fails[0].runner_status, "FAILED");
});

Deno.test("extractFailures: rejects test name containing word FAILED", () => {
  const text = "./src/bar_test.ts => has FAILED marker ... ok (2ms)\nok | 1 passed | 0 failed (1s)\n";
  // The shape "... ok (...)" not "... FAILED (...)"; should yield 0 failures
  const fails = extractFailures(text);
  assertEquals(fails.length, 0);
});

Deno.test("extractFailures: multiple FAILED rows", () => {
  const text = `./src/a_test.ts => group > test A ... FAILED (5ms)
./src/b_test.ts => group > test B ... FAILED (7ms)
ok | 0 passed | 2 failed (1s)
`;
  const fails = extractFailures(text);
  assertEquals(fails.length, 2);
  assertEquals(fails[0].test_file, "./src/a_test.ts");
  assertEquals(fails[1].test_file, "./src/b_test.ts");
});

Deno.test("extractFailures: ANSI-decorated FAILED line", () => {
  const text = "\x1b[31m./src/x_test.ts\x1b[0m => foo: bar \x1b[31m... FAILED (5ms)\x1b[0m\nok | 0 passed | 1 failed (1s)\n";
  const fails = extractFailures(stripAnsi(text));
  assertEquals(fails.length, 1);
  assertEquals(fails[0].test_file, "./src/x_test.ts");
});

Deno.test("extractFailures: BASELINE01 fixture", () => {
  // Real BASELINE01 fail list excerpt
  const text = `
./integration/remote_execution_test.ts => remote execution: enroll over a real socket, dispatch, verbs, leases, scheduling, cancel ... FAILED (33ms)
./integration/scheduled_trigger_inputs_test.ts => scheduled run: a required input supplied only via trigger.inputs resolves and the run completes ... FAILED (22ms)
./src/cli/repo_context_test.ts => requireInitializedRepo - returns context for initialized repo (json mode) ... FAILED (12ms)
FAILED | 12128 passed (214 steps) | 160 failed | 30 ignored (1 step) (1m40s)
`;
  const fails = extractFailures(text);
  assertEquals(fails.length, 3);
  assertEquals(fails[2].test_file, "./src/cli/repo_context_test.ts");
});
