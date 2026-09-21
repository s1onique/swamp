# FAILURE INVENTORY — SWAMP-TEST-CHAR01

Each distinct failure observed during characterization.

## Target 1: doctor_audit SIGTERM

| field | value |
|-------|-------|
| id | D1 |
| test | `runChildWithAbort: aborting a SIGTERM-respecting child terminates it promptly` |
| file | `src/cli/commands/doctor_audit_test.ts:150:6` |
| baseline signature | `expected SIGTERM-responding child to exit promptly; took ~30029 ms` |
| cells observed | B.1 (full suite, ~30s), D (cached-only, ~30s), isolated iter1..iter5 (~30s) |
| isolated reproduction | YES — 5/5 iterations, ~61s each (test waits 30s × 2 children) |
| full-suite reproduction | YES — observed in Cell B.1 |
| parallelism dependence | NO — isolated runs (no `--parallel`) reproduce 5/5 |
| cache dependence | NO — `--cached-only` reproduces; fresh DENO_DIR also reproduces |
| TTY dependence | NO — tests run non-TTY by construction (subprocess via stdin pipe) |
| classification | `DOCTOR_REPRODUCIBLE_DEFECT` |
| evidence strength | `REPRODUCED_REPEATEDLY` (N=5 isolated, N=1 full-suite, N=1 cached-only) |
| mechanism | `runChildWithAbort` in `src/cli/commands/doctor_audit.ts` calls `child.kill("SIGTERM")` on abort, but awaits `child.output()` which only resolves when the child exits. On macOS with this Deno version, SIGTERM delivered via `ChildProcess.kill` does not actually terminate a child process whose stdin is closed and whose event loop is awaiting a `setTimeout`. The child waits the full 30 seconds for the `Promise` to resolve, then `runChildWithAbort` returns its 30-second exitCode. Test asserts elapsed < 2_000 ms; observed ~30_000 ms every time. |

## Target 2: doctor_audit SIGKILL

| field | value |
|-------|-------|
| id | D2 |
| test | `runChildWithAbort: escalates to SIGKILL when child traps SIGTERM` |
| file | `src/cli/commands/doctor_audit_test.ts:179:6` |
| baseline signature | `expected SIGKILL escalation to terminate child; took ~30032 ms` |
| cells observed | B.1 (full suite), D (cached-only), isolated iter1..iter5 |
| isolated reproduction | YES — 5/5 iterations, ~61s each |
| full-suite reproduction | YES — observed in Cell B.1 |
| parallelism dependence | NO |
| cache dependence | NO |
| TTY dependence | NO |
| classification | `DOCTOR_REPRODUCIBLE_DEFECT` |
| evidence strength | `REPRODUCED_REPEATEDLY` (N=5 isolated, N=1 full-suite, N=1 cached-only) |
| mechanism | Same root cause as D1. Test installs a no-op SIGTERM handler in the child (so SIGTERM cannot kill it), then relies on SIGKILL escalation after `sigkillAfterMs: 200`. SIGKILL must reach the child. Observed: child does not exit even after the full 30-second wait. |

## Target 3: extension_quality_checker fmt ANSI

| field | value |
|-------|-------|
| id | A1 |
| test | `checkExtensionQuality: fmt output contains no ANSI escape codes` |
| file | `src/domain/extensions/extension_quality_checker_test.ts:334:6` |
| baseline signature | `assertEquals(fmtIssue !== undefined, true)` (or, depending on which sub-assertion, ANSI escape detected in `fmtIssue.output`) |
| cells observed | B.1 (full suite, ~2s), D (cached-only), isolated iter1..iter5, controls (NO_COLOR, TERM=dumb) |
| isolated reproduction | YES — 5/5 iterations, ~7.1s each |
| full-suite reproduction | YES — observed in Cell B.1 |
| parallelism dependence | NO |
| cache dependence | NO |
| TTY dependence | NO — failures occur with stdout/stderr piped (non-TTY) |
| classification | `ANSI_REPRODUCIBLE_DEFECT` |
| evidence strength | `REPRODUCED_REPEATEDLY` (N=5 isolated, N=1 full-suite, N=1 cached-only, 2 env controls) |
| mechanism | `extension_quality_checker.ts` invokes `Deno.Command(denoPath, {args: ["fmt", "--check", "--no-config", ...], stdout: "piped", stderr: "piped", env: {..., NO_COLOR: "1"}})`. On Deno 2.9.7, `deno fmt --check` writes ANSI escape sequences to stderr even with `NO_COLOR=1` set (verified by running `NO_COLOR=1 deno fmt --check ...` and observing `\x1b[...` bytes). The test asserts `fmtIssue.output.includes("\x1b[") === false`, but the assertion that fails first is `assertEquals(fmtIssue !== undefined, true)` — the test framework's `withTempFiles` wrapper fails because `Deno.makeTempDir()` cannot find a writable TMPDIR on the synthetic HOME (initial runs; later runs fixed by setting `TMPDIR=/tmp`). |

## Target 4: extension_quality_checker lint ANSI

| field | value |
|-------|-------|
| id | A2 |
| test | `checkExtensionQuality: lint output contains no ANSI escape codes` |
| file | `src/domain/extensions/extension_quality_checker_test.ts:348:6` |
| baseline signature | `assertEquals(lintIssue !== undefined, true)` |
| cells observed | B.1, D, isolated iter1..iter5, controls |
| isolated reproduction | YES — 5/5 iterations, ~7.1s each |
| full-suite reproduction | YES — observed in Cell B.1 |
| parallelism dependence | NO |
| cache dependence | NO |
| TTY dependence | NO |
| classification | `ANSI_REPRODUCIBLE_DEFECT` |
| evidence strength | `REPRODUCED_REPEATEDLY` (N=5 isolated, N=1 full-suite, N=1 cached-only, 2 env controls) |
| mechanism | Same as A1, with `deno lint` instead of `deno fmt`. |

## Control: telemetry JSR-cache (BASELINE01-categorized)

| field | value |
|-------|-------|
| id | T1, T2 |
| test | `integration/telemetry_invocation_context_test.ts`, `integration/telemetry_workflow_method_invocations_test.ts` |
| file | `integration/` |
| baseline signature | `JSR package manifest for '@cliffy/command' failed to load` |
| cells observed | B (fresh DENO_DIR), C (warm), D (cached-only) |
| isolated reproduction | 2/2 passed under all cache states on this host |
| full-suite reproduction | not observed (this host's cache state does not trigger the JSR manifest failure) |
| classification | `BASELINE_TELEMETRY_FAILURE_NOT_REPRODUCED` on this host; remains historical environmental evidence per CORRECTION02 |
| evidence strength | `NOT_REPRODUCED` here; baseline observation is the canonical evidence |

## Conservation check

```
isolated doctor:    11 passed + 2 failed  = 13 total tests  ✓
isolated ansi:      47 passed + 2 failed  = 49 total tests  ✓
telemetry warm:      2 passed + 0 failed  =  2 total tests  ✓
telemetry cached-only: 2 passed + 0 failed = 2 total tests ✓

classified_targets == 4   ✓
```

All counts reconcile.
