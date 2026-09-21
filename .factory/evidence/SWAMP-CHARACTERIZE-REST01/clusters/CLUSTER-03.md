# CLUSTER-03 — Doctor-portable terminal-race test (1 test)

## Mechanism

```
src/cli/commands/doctor_audit_test.ts:603:6
"runChildWithAbort: portable — terminal race returns benign
already-terminal outcome, not delivery error"
```

The test (added in production commit `4dc6c86e` from
`SWAMP-DOCTOR-SIGNAL-CAPABILITY01`):

1. Spawns a short-lived child via `Deno.execPath()` (30 ms lifetime).
2. After 100 ms, calls `controller.abort()`.
3. Asserts that `runChildWithAbort` invoked its `_signalSender`
   recording mock exactly once, then the call resolved benignly
   via `child.output()`.

The captured failure is at line 632:

```
at assertEquals (jsr:@std/assert/equals.ts:67:9)
at file:///Volumes/UserData/Users/chistyakov/Projects/SPbNIX/swamp/src/cli/commands/doctor_audit_test.ts:632:5
```

Line 632 is `assertEquals(calls.length, 1)`. Diff:

```
- 0   (actual)
+ 1   (expected)
```

So `_signalSender` was **never called** even though `setTimeout(() => controller.abort(), 100)` fired.
By the time the abort handler executes the child has already
naturally exited via `child.output()`, so the abort listener's
attempt to deliver SIGTERM via the sender was reached AFTER
`runChildWithAbort` had already returned.

## Root cause signature

```
AssertionError at doctor_audit_test.ts:632: assertEquals(calls.length, 1)
```

## Isolation evidence

```
test src/cli/commands/doctor_audit_test.ts => 23 passed | 1 failed (1s)  [run 1, isolated]
test src/cli/commands/doctor_audit_test.ts => 23 passed | 1 failed (1s)  [run 2, isolated]
test src/cli/commands/doctor_audit_test.ts => 23 passed | 1 failed (1s)  [run 3, isolated]
```

(Raw: `clusters/CLUSTER-03/isolation.stdout`.)

N=3 isolated runs, **uniform outcome** (1 failed, same test every
time). Reproducible, not flaky.

## Classification

```
PRIMARY:          PROJECT_DEFECT
CAUSE_OWNER:      SWAMP       (test logic; the abort handler is registered but
                              the function has already returned by the time the
                              abort fires for a 30 ms-lifetime child with a 100 ms
                              abort delay)
HANDLING:         DEGRADED    (test was added by SWAMP-DOCTOR-SIGNAL-CAPABILITY01
                              and was assumed PASS on this substrate; substrate allows
                              it to RUN but the test logic depends on a tighter timing
                              window than the substrate's native arm64 Deno 2.9.7 provides)
EVIDENCE:         REPRODUCED_REPEATEDLY   (N=3 isolated runs, identical outcome)
DOGFOOD_IMPACT:   NON_BLOCKING   (DOGFOOD01 does not rely on this portable terminal-race
                                  assertion; the related real-signal tests are capability-gated
                                  and uniformly pass under the same substrate)
```

## Why PROJECT_DEFECT not FLAKY

Same machine, same conditions, same exact assertion fails every
time. This is a deterministic timing issue with the test's
chosen 30 ms lifetime / 100 ms abort delay. Either the test's
abort delay needs to be shorter than the child's lifetime, or
the test needs to assert against `calls.length === 0` for an
already-terminal outcome (which is the case: after a 30 ms
child exits and `controller.abort()` fires 100 ms later, the
abort-listener runs but the sender is never reached because
`runChildWithAbort` has already returned the child output).

The most likely root cause: the abort handler in
`runChildWithAbort` was originally designed under the
assumption that the child is still in `child.output()` when
`controller.abort()` fires. For a `setTimeout(() => abort(), 100)`
and `makeShortLivedCommand(30)`, the abort is too late.

## Production-code change recommendation (NOT in scope)

Possible repairs for a future ACT:

1. Reduce the test's `setTimeout(() => controller.abort(), 100)` to
   `setTimeout(() => controller.abort(), 10)` so the abort fires
   before the child exits naturally.
2. OR change the assertion to allow `calls.length === 0` when the
   natural `child.output()` resolved before the abort fired.
3. OR explicitly wait for `child` to be in a running state before
   triggering abort.

This ACT does NOT recommend a repair without a dedicated ACT.

## Raw evidence

- `.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stdout` line 19738 area
- `.factory/tmp/SWAMP-CHARACTERIZE-REST01/clusters/CLUSTER-03/isolation.stdout`
