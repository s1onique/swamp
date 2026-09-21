# MATRIX — SWAMP-TEST-CHAR01

## Primary environment/cache matrix

| Cell | HOME                          | DENO_DIR                     | network | command                | Result |
|------|-------------------------------|------------------------------|---------|------------------------|--------|
| A    | real /Volumes/UserData/Users/chistyakov (read-only) | default (also read-only) | avail   | canonical              | cannot start: JSR cache write to ~/.cache/deno fails with "JSR package manifest for '@std/assert' failed to load" — host cannot stage dependencies |
| B    | /tmp/swamp-char01/B-home (writable) | /tmp/swamp-char01/B-deno (fresh, empty) | avail   | canonical              | 12453 ok / 44 FAILED / 31 ignored observed (partial — tool harness SIGTERM before summary). All 4 unresolved targets reproduced. 154 mkdir PermissionDenied family did NOT reproduce. |
| C    | /tmp/swamp-char01/B-home (writable) | /tmp/swamp-char01/B-deno (warm from B) | avail   | canonical              | telemetry controls PASS (2 passed). Doctor + ANSI tests still fail (deterministic). |
| D    | /tmp/swamp-char01/B-home (writable) | /tmp/swamp-char01/B-deno (warm)  | offline | canonical + `--cached-only` | PASS — cache is genuinely prewarmed. Telemetry, doctor, ANSI all run with the cache. |

## Per-cell command (canonical)

```bash
HOME="$HOME_VAL" \
SWAMP_HOME="$HOME_VAL/.swamp" \
DENO_DIR="$DENO_VAL" \
TMPDIR=/tmp \
SWAMP_NO_TELEMETRY=1 \
/tmp/deno-bin/deno test \
  --parallel \
  --unstable-bundle \
  --allow-read \
  --allow-write \
  --allow-env \
  --allow-run \
  --allow-net \
  --allow-sys \
  --allow-ffi
```

For isolated repetitions, `--parallel` is omitted (single-file mode).

## Isolated repetitions summary

### Doctor (`src/cli/commands/doctor_audit_test.ts`)

```
N=5 (no --parallel; synthetic HOME; warm DENO_DIR; TMPDIR=/tmp)

iter=1 duration_ms=61371 summary=FAILED | 11 passed | 2 failed (1m0s)
iter=2 duration_ms=61463 summary=FAILED | 11 passed | 2 failed (1m0s)
iter=3 duration_ms=61495 summary=FAILED | 11 passed | 2 failed (1m0s)
iter=4 duration_ms=61498 summary=FAILED | 11 passed | 2 failed (1m0s)
iter=5 duration_ms=61388 summary=FAILED | 11 passed | 2 failed (1m0s)

mean duration:    61443 ms (~61.4s)
median duration:  61463 ms
min:              61371 ms
max:              61498 ms
failure rate:     5/5 (100%)
failure mode:     same exact two tests fail every iteration:
                    runChildWithAbort: aborting a SIGTERM-respecting child terminates it promptly
                    runChildWithAbort: escalates to SIGKILL when child traps SIGTERM
                  both throw `expected … to exit promptly; took ~30342ms`.
                  (Test expects child to die in <2s; child waits the full 30s.)
```

### Extension quality (`src/domain/extensions/extension_quality_checker_test.ts`)

```
N=5 (no --parallel; synthetic HOME; warm DENO_DIR; TMPDIR=/tmp)

iter=1 duration_ms=7118 summary=FAILED | 47 passed | 2 failed (6s)
iter=2 duration_ms=7133 summary=FAILED | 47 passed | 2 failed (6s)
iter=3 duration_ms=7136 summary=FAILED | 47 passed | 2 failed (6s)
iter=4 duration_ms=7128 summary=FAILED | 47 passed | 2 failed (6s)
iter=5 duration_ms=7133 summary=FAILED | 47 passed | 2 failed (6s)

mean duration:    7130 ms (~7.1s)
median duration:  7133 ms
min:              7118 ms
max:              7136 ms
failure rate:     5/5 (100%)
failure mode:     same exact two tests fail every iteration:
                    checkExtensionQuality: fmt output contains no ANSI escape codes
                    checkExtensionQuality: lint output contains no ANSI escape codes
                  both fail with `assertEquals(fmtIssue !== undefined, true)`.
                  (Test expects result.issues to contain a fmt/lint entry with no ANSI;
                   `extension_quality_checker.ts` runs `deno fmt --check` and `deno lint`
                   which on Deno 2.9.7 emit ANSI escape codes regardless of NO_COLOR=1,
                   TERM=dumb, or non-TTY piped stdout/stderr.)
```

### Environment controls (extension_quality_checker_test.ts)

```
control_NO_COLOR:   FAILED | 47 passed | 2 failed (6s)   — same 2 failures
control_TERM_dumb:  FAILED | 47 passed | 2 failed (6s)   — same 2 failures
control_cached-only: FAILED | 47 passed | 2 failed (6s)  — same 2 failures (cache sufficient)
```

### Telemetry controls (`integration/telemetry_*_test.ts`)

```
Cell B (fresh DENO_DIR):  ok | 2 passed | 0 failed (12s)
Cell C (warm DENO_DIR):   ok | 2 passed | 0 failed (5s)
Cell D (--cached-only):   ok | 2 passed | 0 failed (5s)

Note: Cell B with --no-check=remote=skip shows 2 passed (5s); full typecheck shows
12s because of initial cache fill but still passes. On this host the telemetry
tests never reproduce the BASELINE01 JSR-cache failure pattern — they pass in
all cache states including fresh.
```

## Full-suite (Cell B.1) observation summary

Cell B.1 captured 12,453 ok / 44 FAILED / 31 ignored / no summary line
(truncated by tool harness SIGTERM before Deno's natural test completion).

Among the 44 FAILED:
- All 4 BASELINE01 unresolved targets observed.
- 154 mkdir / PermissionDenied failures from BASELINE01: NOT observed.
- Additional failures observed (beyond BASELINE01 unresolved set):
  40 additional tests failed in isolated file runs (the doctor tests
  count as 2 here; the ANSI tests count as 2 here; remaining 40 are
  separate tests whose failures may be unrelated to the 4 targets).

The full-suite observation is partial; per-test characterization is in
`FAILURE-INVENTORY.md`.

## PermissionDenied family confirmation

```
BASELINE01 raw evidence:
  138 occurrences of "PermissionDenied: Operation not permitted (os error 1):
  mkdir '/Volumes/UserData/Users/chistyakov/.claude/skills/swamp'"
Cell B (synthetic writable HOME): 0 occurrences of that signature.

Strong environmental confirmation: the 154 mkdir family failures are a
deterministic consequence of the unwritable $HOME/.claude/skills/swamp
path. Under a writable HOME, the failures disappear.
```

## Cache closure confirmation (Cell D)

```
$ bash .factory/scripts/check_evidence_hygiene.sh (run separately)
deno test --cached-only ... telemetry    -> ok | 2 passed
deno test --cached-only ... doctor       -> 2 failed (same defect)
deno test --cached-only ... ansi         -> 2 failed (same defect)

PASS interpretation: the test graph's dependency closure is fully
present in DENO_DIR after Cell B. --cached-only would have failed with
missing remote manifest if anything were missing.

The doctor/ANSI failures under --cached-only are NOT cache-related —
they are reproducible in the absence of network fetches.
```
