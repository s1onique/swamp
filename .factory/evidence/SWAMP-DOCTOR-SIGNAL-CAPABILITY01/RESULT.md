# RESULT — ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01

**ACT**: SWAMP-DOCTOR-SIGNAL-CAPABILITY01
**VERDICT**: `SIGNAL_CAPABILITY_HANDLING_REPAIRED`
**SUBJECT**: bcaa9695b7f27f51964a9f41587fdf112b261c89 (unchanged)
**HEAD**: 210302b30793e9533e9751206203366142773e2c (before closure commit)

## TL;DR

Cancellation is now **capability-aware and fail-explicit**:

```
signal_attempt
        ↓
one of
        DELIVERED                 — armed escalation if SIGTERM
        PROCESS_ALREADY_TERMINAL  — benign; child.output() resolves naturally
        CAPABILITY_DENIED         — rejected with ChildSignalDeliveryError
        SIGNAL_ERROR              — rejected with ChildSignalDeliveryError
```

There is no fifth implicit outcome. The substrate-level operation is
unchanged — the VSCodium/macOS sandbox still denies `kill(2)` to
descendant processes. The substrate defect is preserved as-is; only the
*handling* is repaired.

## Test results

Two independent claims are recorded here — runner status and
semantic coverage — because the capability-gated skip is implemented
inside the test body (not as a Deno `t.step({ ignore: true })`),
so the runner counts both real-signal tests as `ok`.

### RUNNER_STATUS (what Deno reported)

```
running 24 tests from ./src/cli/commands/doctor_audit_test.ts
ok | 24 passed | 0 failed (3s)
EXIT=0
```

### SEMANTIC_COVERAGE (what the test bodies actually exercised)

```
portable_tests_executed                  = 22
portable_tests_executed_expected         = 22
real_signal_tests                        = 2
real_signal_executed                     = 0
real_signal_capability_unavailable       = 2
portable_tests_skipped                   = 0
runner_failures                          = 0
```

The real-signal tests are exercised as code (the gate runs, the
reason is logged, the test resolves to `ok`), but their *body*
short-circuits before exercising the real signal path because
`probeChildSignalCapability()` returned `CAN_SIGNAL_CHILD=false`.

Full breakdown in `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/TESTS.md`.

## Denied-signal latency

```
                       Before ACT    After ACT
RED test (5 s child)   5 285 ms      54 ms     (>97× reduction)
T4 (denied SIGTERM)    n/a           32 ms
T7 (denied SIGKILL)    n/a           114 ms
Real-signal tests      30 s + fail   capability-gated SKIP (~520 ms)
```

ACT §18 targets `< 2 s`, preferably much less. Actual: 32-114 ms for
denied-signal paths.

## Files changed

```
M src/cli/commands/doctor_audit.ts
M src/cli/commands/doctor_audit_test.ts
```

No other production files. Scope verified via `git diff --name-only
<start>..HEAD`.

## Factory files

- New ACT plan: `.factory/acts/SWAMP-DOCTOR-SIGNAL-CAPABILITY01.md`
- New evidence packet: `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/`
- New raw: `.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/`
- Board: `.factory/epic-board.md` (row added, state CLOSED)

## Required classification

```
CAUSE_OWNER       = SUBSTRATE
HANDLING_QUALITY  = ROBUST
```

CAUSE_OWNER is the macOS sandbox (inherited from prior ACTs).
HANDLING_QUALITY is ROBUST because the denied-signal path is now
explicit, bounded, and the failure semantics are deterministically tested.

## Closure invariants (ACT §33)

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

Verified:
- `NO_SIGNAL_ERROR_SWALLOWED` — verified by T4, T5, T7, and the RED
  test (which now passes in 54 ms instead of timing out).
- `PERMISSION_DENIED_IS_EXPLICIT` — verified by T4 and the capability
  probe (`CAN_SIGNAL_CHILD=false reason=PermissionDenied`).
- `SIGKILL_DELIVERY_FAILURE_IS_EXPLICIT` — verified by T7
  (`ChildSignalDeliveryError` with `phase: "escalation"`).
- `REAL_SIGNAL_TESTS_ARE_CAPABILITY_GATED` — verified by the
  `[capability-gated skip]` log line on both real-signal tests.
- `PORTABLE_DENIAL_TESTS_RUN` — T4 and T7 both run on this substrate
  and pass.
- `NO_SIGNAL_LATENCY_BOUND_WEAKENED` — T4 asserts <500 ms; T7 asserts
  <1500 ms; both bound the latency to a small budget rather than the
  child's natural lifetime.
- `NO_SUBSTRATE_FINGERPRINT_IN_PRODUCTION` — `grep` of
  `src/cli/commands/doctor_audit.ts` for VSCodium/sandbox/macOS-process-name
  patterns: zero matches.
- `NORMAL_CHILD_COMPLETION_PRESERVED` — verified by T2 and T3.
- `NO_UNHANDLED_PROMISE_REJECTION` — verified by test execution
  (no `Uncaught (in promise)` lines in any test output).
- `NO_SWAMP_PRODUCTION_SCOPE_DRIFT` — verified by
  `git diff --name-only <start>..HEAD | grep -v '^.factory/'` lists
  exactly two files.
- `BASELINE_RAW_EVIDENCE_UNCHANGED` — verified by
  `sha256sum .factory/tmp/native-baseline/test.stdout` ==
  `ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417`.
- `REPORTED_TEST_STATUS_AGREES_WITH_PROCESS_EXIT_CODE` — deno test
  exit=0 agrees with `ok | 24 passed | 0 failed`.
- `BOARD_STATE_AGREES_WITH_ACT_STATE` — board row updated to CLOSED.
- `POLICY_EQUALS_VERIFIER_SCOPE_EQUALS_CLAIM` — verifier
  `.factory/scripts/check_evidence_hygiene.sh <ACT_RANGE>` covers
  exactly the policy this ACT claims to enforce.

## Negative claims (ACT §25)

```
PermissionDenied is not swallowed                 = true (T4 + RED)
Generic signal error is not swallowed                = true (T5)
SIGKILL error is not swallowed                     = true (T7)
Denied SIGTERM does not arm a fake escalation      = true (T4 sequence: exactly 1 attempt)
Capability-unavailable integration skip != skip
  portable logic tests                             = true (T1-T8 always run)
Process-name / env detection is not used          = true (grep clean)
Successful normal child path is unchanged          = true (T2 + T3)
```

## Evidence hygiene

- Raw evidence: `.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/**`
  (immutable, hash-pinned in `raw-sha256.txt`).
- Authored artifacts: `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/**`
  + `.factory/acts/SWAMP-DOCTOR-SIGNAL-CAPABILITY01.md`
  + `.factory/epic-board.md`.
- BASELINE01 raw SHA preserved:
  `ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417`.

## Recommended next ACT

`ACT-SWAMP-ANSI-OUTPUT01` — pick the production vs. test fix for the
ANSI defect (A1/A2) reclassified in TEST-CHAR01-CORRECTION01.

---

# END RESULT — ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01
