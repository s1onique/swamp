# CLUSTER-03 (reframed) — test-contract ambiguity, not a timing edge

> **REVISED FRAMING.** The prior ACT described this cluster as a
> PROJECT_DEFECT timing edge ("test's 30 ms child lifetime + 100 ms
> abort delay too tight on arm64 substrate"). The reviewer audit
> showed that the description conflates the test scenario with a
> timing implementation detail. This doc re-frames CLUSTER-03 as a
> **test-contract ambiguity** that should be addressed by an ACT
> focused on the contract, not the timing.

| Field | Value |
|---|---|
| Cluster ID | CLUSTER-03 |
| Count | 1 |
| Test name | runChildWithAbort: portable — terminal race returns benign already-terminal outcome, not delivery error |
| Test file | src/cli/commands/doctor_audit_test.ts:603 |
| Runner line | assertEquals(calls.length, 1) actual=0 expected=1 at line 632 |
| Primary classification | TEST_CONTRACT_AMBIGUITY (reclassified from PROJECT_DEFECT) |
| Cause owner | SWAMP (test contract) |
| Evidence | REPRODUCED_REPEATEDLY (3 isolated runs, deterministic, NOT flaky) |
| Dogfood blocker | yes (test asserts one scenario while fixture creates another) |
| Handling | DEFERRED — addressed by SWAMP-DOCTOR-TERMINAL-RACE01 (proposed) |

## The contract ambiguity

The test asserts TWO things implicitly:

  - Implicit invariant A: `calls.length === 1` — i.e. the signal
    sender was invoked at least once. This holds ONLY when the abort
    happens BEFORE the child has naturally exited.

  - Implicit invariant B (the test's stated name): "terminal race
    returns benign already-terminal outcome" — i.e. even if the sender
    throws `TypeError("Child process has already terminated")`,
    `runChildWithAbort` resolves cleanly with `exitCode === 0`.

The fixture is:

```ts
const cmd = makeShortLivedCommand(30);   // child exits after ~30ms
setTimeout(() => controller.abort(), 100); // abort fires at ~100ms
```

The child has already exited ~70ms before abort. So `_signalSender` is
NEVER reached, the call list is empty, and the assertion
`assertEquals(calls.length, 1)` fails with `actual=0 expected=1`.

The observed failure is therefore the CONSISTENT, EXPECTED outcome of
the fixture's scenario. The test name says one thing, the assertion
asserts the opposite scenario.

## The two non-equivalent invariants

| Invariant | Scenario | Fixture | Expected calls.length | Asserted in test |
|---|---|---|---|---|
| A | abort while child alive | child lifetime > abort delay | 1 | YES |
| B | abort after child exited | child lifetime < abort delay | 0 | NO (asserts 1) |

Both are reasonable invariants for a portable cancellation suite, but
they are NOT equivalent. The test's name and comment (lines 596–602)
speak in terms of B; the assertion enforces A.

## Why "tighten the abort delay" is the wrong repair

The naive repair is "make abort fire before the child exits" (e.g.
swap the 30 ms and 100 ms). This converts the test from scenario B
(named contract) to scenario A (asserted contract) and silently
turns the test into a different test.

What the production code's behavior means:

  - If scenario A holds (abort while alive): the signal sender
    attempts SIGTERM, the child has already exited by the time the
    syscall lands, and the kernel returns EPERM / "already
    terminated". `runChildWithAbort` must catch this and resolve
    benignly with exitCode 0.

  - If scenario B holds (abort after natural exit): the sender is
    never reached, `runChildWithAbort` just awaits `child.output()`,
    and exits 0.

Both behaviors are correct. They are NOT the same test. Conflating
them loses information about whether the production code's
"catch-already-terminated" path is exercised.

## The correct next ACT

SWAMP-DOCTOR-TERMINAL-RACE01 (not SWAMP-DOCTOR-PORTABLE-TIMING01,
which would suggest fixing a timing knob instead of choosing a
contract).

That ACT's first deliverable should be to decide which of A or B the
portable suite wants to assert, then EITHER:

  - Split the test into two named tests (one per invariant), each
    with a fixture that places the abort in the right window. Or
  - Adjust the fixture so the existing test is unambiguously one
    invariant, and rename the test to match.

That is a contract-level decision, not a timing-level one. The prior
ACT's recommendation — "tighten abort delay" — was the wrong
direction because it changes the scenario.

## What does NOT change

- The failure is still deterministic and reproduces 3/3 isolated
  runs. It is NOT flaky.
- **Narrowed in CORRECTION02:** The observed failure is explained
  by the test contract/fixture mismatch and is not evidence of a
  production-code failure. This is a weaker claim than
  "production code is correct". Specifically:
    - The test asserts scenario A (`calls.length === 1`). The
      fixture creates scenario B (child exits before abort). The
      observed failure (`calls.length === 0`) is the consistent
      outcome of scenario B.
    - The production path that handles an already-terminated
      sender — i.e. catches the TypeError on scenario A and
      no-ops on scenario B — has not been independently proven
      correct by this ACT. It is merely not implicated by
      THIS failure.
    - A separate portable test would be required to claim
      "production code is correct". This ACT does not run one.
    - The test fixture (line 613-614) is at fault relative to
      the asserted invariant on line 632.
- This is still the only failure in the prior ACT's inventory that
  is caused by SWAMP, not the substrate.
- The historical cause attribution (introduced by production commit
  4dc6c86e in SWAMP-DOCTOR-SIGNAL-CAPABILITY01) is unchanged.

## Raw evidence paths

- .factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stdout (original)
  - search: "runChildWithAbort: portable — terminal race"
- src/cli/commands/doctor_audit_test.ts:130-200 (fixture helpers)
- src/cli/commands/doctor_audit_test.ts:596-650 (test T8)
- (no new isolated runs needed in this correction ACT; the prior
  ACT's reproduction already proves determinism)
