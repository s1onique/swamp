# RED — Demonstrating the SIGTERM-PermissionDenied swallow defect

## Test name

`runChildWithAbort: SIGTERM PermissionDenied is surfaced explicitly, not swallowed`

## Driver

- Child: 5-second natural lifetime (`await new Promise((r) => setTimeout(r, 5000))`).
- Sender: `makeRecordingSender([new Deno.errors.PermissionDenied("EPERM: Operation not permitted")])`.
  The first signal attempt (SIGTERM) raises `Deno.errors.PermissionDenied`.
- Abort: triggered at 50 ms via `controller.abort()`.
- Expected: prompt rejection with `ChildSignalDeliveryError` within <1 s.

## Observed on unfixed production code

```
error: Error: expected prompt resolution on SIGTERM PermissionDenied; took 5285.75575ms
      (prior defect: swallow + natural child lifetime wait)
```

- Elapsed: 5285 ms (waited for natural child completion).
- Outcome: timeout assertion failed; no rejection observed (the swallow
  hid the EPERM and `child.output()` only resolved when the child
  naturally exited).

## Substrate at RED time

```
uname: Darwin MacBook-Pro-3.local 23.6.0 Darwin Kernel Version 23.6.0
       arm64 arm
deno: 2.9.7 (stable, release, x86_64-apple-darwin) under Rosetta
file: Mach-O 64-bit executable x86_64
HEAD: 210302b30793e9533e9751206203366142773e2c
subject: bcaa9695b7f27f51964a9f41587fdf112b261c89 (merge-base)
capture: 2026-09-21T08:58:37Z
```

## Raw evidence (immutable)

```
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.stdout      — full test output
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.stderr      — Deno's error line
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.exitcode    — deno test exit code (=1)
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.substrate.txt — substrate + version metadata
```

Hashes (sha256) are pinned in `.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/raw-sha256.txt`.

## Required claim

> `SIGNAL_CAPABILITY_DENIED_IS_NOT_SILENT` — must fail before production modification.

Satisfied: the test failed in 5285 ms on the unfixed code, with the
exact message naming the swallow defect.
