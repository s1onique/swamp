# CAPABILITY MATRIX — Cancellation semantics

Pre-ACT vs. post-ACT capability matrix (ACT §23).

| Layer | Operation | Current VSCodium substrate | Semantics after ACT |
|-------|-----------|----------------------------|---------------------|
| OS / substrate | deliver SIGTERM | denied / EPERM | observed capability denial |
| OS / substrate | deliver SIGKILL | denied / EPERM | observed capability denial |
| Swamp | request graceful cancellation | possible (request could be sent) | explicit result (4 typed outcomes) |
| Swamp | request escalation | possible (timer could be armed) | explicit result |
| Swamp | interpret `kill()` error | currently conflated (swallowed) | classified into delivered / already-terminal / capability-denied / failed |
| Tests | real signal behaviour | unavailable | capability-skipped via observed probe |
| Tests | denied-signal logic | deterministically available | deterministically tested via injected `_signalSender` seam |

## Per-layer outcome count conservation

ACT §24 requires:

```
signal_attempts = delivered + already_terminal + capability_denied + failed
```

For each cancellation flow (one SIGTERM attempt + at most one SIGKILL attempt):

```
total_attempts    = SIGTERM_count + SIGKILL_count
                   (0, 1, or 2 depending on flow)
classified_total  = sum(per-attempt classification counts)
classified_total == total_attempts                  (no implicit outcomes)
```

`attemptSignal` returns exactly one outcome per call. Production callers
either consume the outcome into a `delivered` escalation arm, or reject
the race. No path swallows an outcome.

## Conservation laws verified

Two independent dimensions — runner status and semantic coverage —
must both satisfy their conservation invariants:

```
# Runner status (what Deno reported)
runner_passed + runner_failed + runner_ignored == runner_total
24 + 0 + 0 == 24                                            (PASS)

# Real-signal semantic coverage
real_signal_executed + real_signal_capability_unavailable == real_signal_total
0 + 2 == 2                                                  (PASS)

# Portable semantic coverage
portable_tests_executed == portable_tests_expected
22 == 22                                                    (PASS)

# Per-flow outcome conservation (the cancellation contract itself)
classified_total == total_attempts                           (PASS — verified per test)
```

## Substrate vs. ACT responsibility

Reactivity label: `CAUSE_OWNER = SUBSTRATE` — the macOS sandbox
prevents signal delivery to descendant processes (root cause).

This ACT changes only `HANDLING_QUALITY`. The substrate operation
itself remains denied.
