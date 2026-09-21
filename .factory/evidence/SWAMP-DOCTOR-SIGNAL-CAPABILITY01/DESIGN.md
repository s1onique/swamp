# DESIGN — Capability-aware subprocess cancellation

## Problem statement

`runChildWithAbort` previously conflated three different outcomes of
`child.kill()` into "ignore and continue":

1. The child had already exited — benign race.
2. The OS refused permission — capability denial.
3. The kill primitive failed for any other reason — unspecified delivery
   failure.

Conflation (2) into (1) caused the call to await `child.output()` for the
child's natural lifetime, producing 30-second stalls on substrates that
deny signal delivery.

## Separation of concerns (ACT §5)

| Question | Pre-ACT answer    | Post-ACT answer                |
|----------|-------------------|--------------------------------|
| Could the signal be requested from the OS? | unknowable | classified into 4 typed outcomes |
| Did the child subsequently terminate?       | no probe   | raced via `child.output()`     |

The implementation never infers "process gone" from a bare `kill()` throw.
It only returns `already-terminal` when the OS reports
`Deno.errors.NotFound` (or `TypeError("Child process has already terminated")`)
— explicit evidence, not absence of evidence.

## API surface

### New exports (`src/cli/commands/doctor_audit.ts`)

```ts
export type SignalSender = (child: Deno.ChildProcess, signal: Deno.Signal) => void;
export const defaultSignalSender: SignalSender = (child, sig) => { child.kill(sig); };

export type CancellationPhase = "graceful" | "escalation";

export class ChildSignalDeliveryError extends UserError {
  readonly signal: Deno.Signal;
  readonly pid?: number;
  readonly phase: CancellationPhase;
  override readonly cause?: unknown;
}

export type SignalAttempt =
  | { kind: "delivered"; signal: Deno.Signal }
  | { kind: "already-terminal"; signal: Deno.Signal }
  | { kind: "capability-denied"; signal: Deno.Signal; cause: unknown }
  | { kind: "failed"; signal: Deno.Signal; cause: unknown };

export function attemptSignal(
  child: Deno.ChildProcess,
  signal: Deno.Signal,
  sender: SignalSender,
): SignalAttempt;
```

### Changed exports

`runChildWithAbort` gains an optional `_signalSender` parameter on its
existing `opts` argument. Production callers never set it (default
behaviour unchanged). The function body is rewritten to race
`child.output()` against a `Promise` that settles via either natural
completion or an abort listener that classifies the kill attempt.

## Cancellation flow (production)

```
abort signal received
        ↓
attemptSignal(SIGTERM)
        ↓
one of
        delivered          → arm escalation timer
        already-terminal   → return; let output() resolve
        capability-denied  → reject(ChildSignalDeliveryError, phase=graceful)
        failed             → reject(ChildSignalDeliveryError, phase=graceful)

escalation timer fires
        ↓
attemptSignal(SIGKILL)
        ↓
one of
        delivered          → return; let output() resolve
        already-terminal   → return; let output() resolve
        capability-denied  → reject(ChildSignalDeliveryError, phase=escalation)
        failed             → reject(ChildSignalDeliveryError, phase=escalation)
```

The promise returned to the caller rejects *before* `child.output()`
resolves — eliminating the 30-second stall on substrate-denied signals.

## Test seam

`_signalSender` is an optional parameter on `runChildWithAbort`'s `opts`
argument. Its underscore prefix marks it `@internal`. Production code
(`makeSwampSpawnFn`) calls `runChildWithAbort(cmd, stdin, signal)`
without an `opts` argument — the default sender delegates to
`ChildProcess.kill`. Tests pass a stub via `opts._signalSender` to make
cancellation outcomes deterministic without depending on host signal
delivery.

Constraints satisfied:

- Production default == real `ChildProcess.kill`.
- Test injection cannot change ordinary production callers (only the
  `_signalSender` parameter is mutable per call).
- No global mutable test hook.
- No environment variable controlling production signal semantics.
- No broad abstraction framework.

## Error contract

`ChildSignalDeliveryError` extends `UserError` so it inherits the
JSON-friendly `code` field convention. The `code` is
`"subprocess_signal_unavailable"`. Production callers that throw
`UserError` see this surfaced as a non-zero exit by the standard CLI
error machinery; tests assert on the class directly via
`instanceof ChildSignalDeliveryError`.

## Cleanup contract

The `childCompletion` promise (which performs stdin write + `child.output()`)
is always retained and `.then(() => {}, () => {})`'d in the `finally` block
if the call was settled through cancellation. This guarantees no
unhandled promise rejection even when the child continues running
because the substrate denied the signal.

## Files

- `src/cli/commands/doctor_audit.ts` — implementation
- `src/cli/commands/doctor_audit_test.ts` — tests + probe
