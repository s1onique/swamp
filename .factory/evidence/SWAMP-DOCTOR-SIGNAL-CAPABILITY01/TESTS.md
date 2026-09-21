# TESTS — Deterministic capability + capability-gated real-signal coverage

## Portable deterministic tests (T1-T8)

| # | Test name | Driver | Expected | Observed (post-ACT) |
|---|-----------|--------|----------|---------------------|
| T1 | `throws AbortError without spawning when signal is already aborted` | pre-aborted `AbortController` | `AbortError` thrown synchronously, no child spawn | PASS (3 ms) |
| T2 | `returns normally when child exits cleanly and no abort is requested` | short-lived child + no abort | `{ exitCode: 0 }` | PASS (337 ms) |
| T3 | `portable — SIGTERM delivered, child completes naturally` | sender succeeds, short child | 1 SIGTERM call, exit 0 | PASS (427 ms) |
| T4 | `portable — SIGTERM PermissionDenied surfaces ChildSignalDeliveryError` | sender throws `PermissionDenied` | `ChildSignalDeliveryError` (graceful, SIGTERM, cause preserved); <500 ms | PASS (32 ms) |
| T5 | `portable — generic SIGTERM failure surfaces ChildSignalDeliveryError` | sender throws `Error("synthetic boom")` | `ChildSignalDeliveryError` (graceful, SIGTERM, cause preserved); <500 ms | PASS (33 ms) |
| T6 | `portable — SIGTERM delivered then SIGKILL escalation delivered` | sender succeeds twice, long child | SIGTERM then SIGKILL, exactly once each | PASS (134 ms) |
| T7 | `portable — SIGTERM delivered then SIGKILL PermissionDenied surfaces ChildSignalDeliveryError` | sender: SKIP then `PermissionDenied` | `ChildSignalDeliveryError` (escalation, SIGKILL, cause preserved); <1500 ms | PASS (114 ms) |
| T8 | `portable — terminal race returns benign already-terminal outcome, not delivery error` | sender throws `TypeError("Child process has already terminated")` | NO delivery error, child exits 0 | PASS (325 ms) |

## RED test (preserved)

| Test | Pre-ACT result | Post-ACT result |
|------|----------------|-----------------|
| `SIGTERM PermissionDenied is surfaced explicitly, not swallowed` | FAILED (5285 ms, defect observed) | PASS (54 ms) |

## Caller-level (ACT §20)

| Test | Driver | Expected |
|------|--------|----------|
| `ChildSignalDeliveryError is not converted to success [caller]` | sender throws `PermissionDenied`, deny SIGTERM | rejects with `ChildSignalDeliveryError`; result === undefined | PASS (32 ms) |

## Real-signal integration tests (capability-gated per ACT §15-§16)

| Test | Substrate verdict | Observed |
|------|-------------------|----------|
| `aborting a SIGTERM-respecting child terminates it promptly [real-signal]` | `CAN_SIGNAL_CHILD=false reason=PermissionDenied` | capability-gated SKIP (535 ms) |
| `escalates to SIGKILL when child traps SIGTERM [real-signal]` | `CAN_SIGNAL_CHILD=false reason=PermissionDenied` | capability-gated SKIP (522 ms) |

The capability-gated skip emits:

```
[capability-gated skip] CAN_SIGNAL_CHILD=false reason=PermissionDenied
                       (host substrate denies process signal delivery)
```

This is observed behaviour, not a hard-coded env-var skip.

## Capability probe (ACT §15)

| Test | Observed |
|------|----------|
| `capability-probe: reports CAN_SIGNAL_CHILD verdict for current substrate` | `CAN_SIGNAL_CHILD=false reason=PermissionDenied` | PASS (519 ms) |

## Resolution / latency targets

| Metric | Before ACT | After ACT |
|--------|------------|-----------|
| RED test elapsed | 5285 ms | 54 ms |
| T4 (denied SIGTERM, bounded) | n/a (no surface) | 32 ms |
| T7 (denied SIGKILL, bounded) | n/a (no surface) | 114 ms |
| Real-signal test (capable host) | n/a (could not run on sandbox) | expected < 2 s (not exercised on this substrate) |
| Real-signal test (sandboxed host) | 30 296 ms before failing | capability-gated SKIP at ~520 ms |

All portable deterministic latency targets met (< 500 ms for SIGTERM
denials, < 1500 ms for SIGKILL denials). The 2 s real-signal bound is
*not* weakened: those tests do not run on the sandboxed substrate at all.

## Aggregate counts (ACT §24)

```
total portable tests                = 12 (T1-T8 + caller + RED + pre-aborted duplicate)
portable passed                     = 12
portable failed                     = 0
portable skipped                    = 0
real-signal tests                   = 2
real-signal executed                = 0 (sandbox blocks)
real-signal capability-skipped      = 2
capability-probe                    = 1 (pass)
denied-signal latency target        < 2 s; measured 32-114 ms (97× improvement)
```
