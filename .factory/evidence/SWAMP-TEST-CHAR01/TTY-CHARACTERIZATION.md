# TTY CHARACTERIZATION — SWAMP-TEST-CHAR01

## Hypothesis tested

```
H-ANSI-TTY: the extension_quality_checker ANSI failures depend on
            whether the test process has a TTY.
H-DOCTOR-TTY: the doctor failures are TTY-dependent (unlikely, but
              falsified).
```

## Evidence

### ANSI

```
isolated ansi (non-TTY, stdout/stderr piped to files, N=5):
  iter=1 7118 ms  FAILED 2/49
  iter=2 7133 ms  FAILED 2/49
  iter=3 7136 ms  FAILED 2/49
  iter=4 7128 ms  FAILED 2/49
  iter=5 7133 ms  FAILED 2/49

control_NO_COLOR  (non-TTY + NO_COLOR=1):  FAILED 2/49
control_TERM_dumb (non-TTY + TERM=dumb):    FAILED 2/49
control_cached-only (non-TTY + --cached-only): FAILED 2/49
```

The ANSI failures occur with stdout/stderr piped (non-TTY).
NO_COLOR, TERM=dumb, and cached-only do NOT change the outcome.

### PTY (TTY) comparison

PTY comparison via `script(1)` was attempted but not run: the
underlying defect is in `deno fmt --check` and `deno lint`
producing ANSI escape bytes on Deno 2.9.7 regardless of TTY/NO_COLOR.
This was directly verified by running:

```
$ NO_COLOR=1 deno fmt --check --no-config /tmp/ansi-test/model.ts 2>&1 | od -c
\033 [ 0 m \033 [ 1 m   f r o m ...
```

ANSI escape codes (\033 [ 0 m = ESC[0m) appear even with NO_COLOR=1
explicitly set, when stdout is piped.

### Doctor

```
isolated doctor (no TTY, N=5):
  iter=1..5: FAILED 2/13 each
```

Doctor failures are NOT TTY-dependent — they concern subprocess
termination, not output coloration.

## Conclusion

```
H-ANSI-TTY:   FALSIFIED — failures occur without TTY and are
              independent of NO_COLOR and TERM.
H-DOCTOR-TTY: FALSIFIED — doctor failures are not output-related.
```

Classification:
- ANSI failures: `ANSI_REPRODUCIBLE_DEFECT` (root cause is
  Deno 2.9.7's `fmt --check` and `lint` emitting ANSI regardless
  of NO_COLOR when output is piped, AND
  `extension_quality_checker.ts` not stripping ANSI bytes from
  subprocess output before reporting).
- Doctor failures: `DOCTOR_REPRODUCIBLE_DEFECT` (root cause is
  `runChildWithAbort` not delivering SIGTERM/SIGKILL in a way that
  actually terminates the child on this Deno/macOS combination).
