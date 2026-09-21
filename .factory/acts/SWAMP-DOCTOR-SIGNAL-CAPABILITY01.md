# ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01

## Goal

Make Swamp's `doctor audit` subprocess cancellation **capability-aware and fail-explicit**.

The production code in `runChildWithAbort` previously assumed any
exception from `child.kill()` meant "child already exited" and silently
returned from the abort handler. That assumption is false on the
characterized VSCodium/macOS sandbox substrate: `child.kill("SIGTERM")`
throws `Deno.errors.PermissionDenied` (`EPERM: Operation not permitted`)
because the macOS sandbox blocks signal delivery to descendant processes.

The swallowed EPERM turned a fast, deterministic cancellation failure
into a 30-second stall on `await child.output()` waiting for natural
child completion. This ACT repairs the *handling* of signal-delivery
failures (not the substrate that denies them): every signal attempt
must produce one of four typed outcomes and never silently claim success.

## State

- **Prior ACTs**: SWAMP-BASELINE01 (CLOSED), SWAMP-TEST-CHAR01 (CLOSED),
  SWAMP-TEST-CHAR01-CORRECTION01 (CLOSED — confirmed substrate-denies-signal).
- **SUBJECT**: `bcaa9695b7f27f51964a9f41587fdf112b261c89` (unchanged).
- **Subject SHA verified** before edits — `git status` clean, `HEAD ==
  210302b…`, `merge-base HEAD upstream/main == SWAMP_SUBJECT`.

## Subject

```text
SUBJECT: bcaa9695b7f27f51964a9f41587fdf112b261c89
DENO_VERSION: 2.9.7
HOST: Darwin arm64 arm 23.6.0
SUBSTRATE_PARENT: VSCodium Helper (Plugin) --enable-sandbox (inherited)
```

## Files

### Production changes (scope-limited per ACT §3)

- `src/cli/commands/doctor_audit.ts` — repair the cancellation contract.
- `src/cli/commands/doctor_audit_test.ts` — add deterministic portable
  tests + capability-gate the existing real-signal tests.

No other Swamp production files modified. Per ACT §27, a `git diff
--name-only <start>..HEAD` must list only these two paths and `.factory/**`.

### Factory material

- New ACT plan: `.factory/acts/SWAMP-DOCTOR-SIGNAL-CAPABILITY01.md` (this file).
- New evidence: `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/`.
- New raw: `.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/`.
- Board update: `.factory/epic-board.md` row `SWAMP-DOCTOR-SIGNAL-CAPABILITY01`.

## Design

### Cancellation result vocabulary

Introduce a discriminated `SignalAttempt`:

```ts
type SignalAttempt =
  | { kind: "delivered";         signal: Deno.Signal }
  | { kind: "already-terminal";  signal: Deno.Signal }
  | { kind: "capability-denied"; signal: Deno.Signal; cause: unknown }
  | { kind: "failed";            signal: Deno.Signal; cause: unknown };
```

Classified by `attemptSignal(child, signal, sender)`:

| Cause from `sender`                                  | Outcome               |
|------------------------------------------------------|-----------------------|
| (no throw)                                           | `delivered`           |
| `Deno.errors.NotFound` (`ESRCH: No such process`)    | `already-terminal`    |
| `TypeError("Child process has already terminated")`  | `already-terminal`    |
| `Deno.errors.PermissionDenied` (`EPERM: …`)          | `capability-denied`   |
| any other                                            | `failed`              |

`already-terminal` is the only "benign" failure — it requires positive
evidence that the OS reports the process as gone, not merely that `kill()`
threw. Other failures are surfaced explicitly.

### Error contract

```ts
class ChildSignalDeliveryError extends UserError {
  readonly signal: Deno.Signal;
  readonly pid?: number;
  readonly phase: CancellationPhase;   // "graceful" | "escalation"
  override readonly cause?: unknown;
}
```

The `code` field is `"subprocess_signal_unavailable"` so the JSON error
surface can distinguish this from other UserErrors.

### Cancellation flow (production)

1. Pre-aborted signal: throw `DOMException("doctor audit aborted", "AbortError")` (unchanged).
2. Spawn child; race `child.output()` against an abort listener.
3. On SIGTERM attempt:
   - `delivered` → arm escalation timer (default 3 s).
   - `already-terminal` → return; `child.output()` will resolve naturally.
   - `capability-denied` / `failed` → reject the race with
     `ChildSignalDeliveryError(phase: "graceful", …)`; no escalation armed.
4. On SIGKILL attempt (escalation):
   - `delivered` / `already-terminal` → return; `child.output()` will resolve.
   - `capability-denied` / `failed` → reject the race with
     `ChildSignalDeliveryError(phase: "escalation", …)`.
5. Cleanup: `child.output()` is always handled (no unhandled rejection).

### Test seam

`runChildWithAbort` accepts an optional `_signalSender` (underscore
prefix marks it `@internal`). Production callers (`makeSwampSpawnFn`)
never set it. The default delegates to `ChildProcess.kill`. This is NOT
a global mutable hook, NOT an environment variable, and cannot affect
ordinary production callers — satisfies ACT §7.

### Capability probe

`probeChildSignalCapability()` is a per-test probe: spawn a short-lived
child (250 ms natural lifetime), attempt `child.kill("SIGTERM")`,
classify via the same `attemptSignal` logic. The probe verdict gates
the two existing real-signal integration tests:

- `CAN_SIGNAL_CHILD=true`  → run normally with the original latency expectation.
- `CAN_SIGNAL_CHILD=false` → SKIP with explicit
  `[capability-gated skip] CAN_SIGNAL_CHILD=false reason=…` log line.

There is no environment-variable skip switch; the skip is observed
through substrate behaviour.

## Required design contracts preserved

- `T1 — pre-aborted signal` → `AbortError` thrown (no child spawn).
- `T3 — SIGTERM delivered` → exactly one SIGTERM call; child completes naturally.
- `T4 — SIGTERM capability denied` → `ChildSignalDeliveryError` (phase `graceful`,
  signal `SIGTERM`, cause preserved); bounded completion (< 500 ms).
- `T5 — generic SIGTERM failure` → `ChildSignalDeliveryError`; cause preserved.
- `T6 — SIGKILL escalation success` → exactly one SIGTERM, then exactly one SIGKILL.
- `T7 — SIGKILL capability denied` → `ChildSignalDeliveryError` (phase `escalation`,
  signal `SIGKILL`, cause preserved); bounded completion (< 1500 ms).
- `T8 — terminal race` → benign `already-terminal` outcome, no false denial.

## RED state

Before production modifications, the RED test
`runChildWithAbort: SIGTERM PermissionDenied is surfaced explicitly, not swallowed`
FAILED on the unfixed production code:

- Driver: a 5-second-lived child + a `_signalSender` that throws
  `Deno.errors.PermissionDenied("EPERM: …")` on the SIGTERM attempt.
- Expected: prompt rejection (< 1 s) with `ChildSignalDeliveryError`.
- Observed: 5 285 ms (waited for natural child completion); rejection: none.

Raw RED evidence (immutable, hash-pinned):
`.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/{red.stdout,red.stderr,red.exitcode,red.substrate.txt}`

## GREEN state

After production modifications, the same test PASSES in 54 ms (vs the
5 285 ms unfixed baseline) — a >97× reduction in denied-signal latency.

Full test run (24 tests):
- 22 PASS in ~3 s
- 2 real-signal tests capability-gated SKIP (probe verdict: `CAN_SIGNAL_CHILD=false reason=PermissionDenied`)
- 0 FAIL
- Exit code 0

## Files changed

```
M src/cli/commands/doctor_audit.ts
M src/cli/commands/doctor_audit_test.ts
```

`.factory/**` is unchanged at the moment of commit (only this ACT plan
+ evidence + raw are added during closure).

## Closure invariants

```
NO_SIGNAL_ERROR_SWALLOWED=true
PERMISSION_DENIED_IS_EXPLICIT=true
SIGKILL_DELIVERY_FAILURE_IS_EXPLICIT=true
REAL_SIGNAL_TESTS_ARE_CAPABILITY_GATED=true
PORTABLE_DENIAL_TESTS_RUN=true
NO_SIGNAL_LATENCY_BOUND_WEAKENED=true
NO_SUBSTRATE_FINGERPRINT_IN_PRODUCTION=true
NORMAL_CHILD_COMPLETION_PRESERVED=true
NO_UNHANDLED_PROMISE_REJECTION=true
NO_SWAMP_PRODUCTION_SCOPE_DRIFT=true
BASELINE_RAW_EVIDENCE_UNCHANGED=true
REPORTED_TEST_STATUS_AGREES_WITH_PROCESS_EXIT_CODE=true
BOARD_STATE_AGREES_WITH_ACT_STATE=true
POLICY_EQUALS_VERIFIER_SCOPE_EQUALS_CLAIM=true
```

---

# END ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01
