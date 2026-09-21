# RESULT — ACT-SWAMP-TEST-CHAR01

**ACT**: SWAMP-TEST-CHAR01

**VERDICT**: `TEST_SUITE_HAS_REPRODUCIBLE_DEFECTS` (initial verdict)

**SUPERSEDED BY**: `SWAMP-TEST-CHAR01-CORRECTION01` for substrate-binding claims.
See `.factory/evidence/SWAMP-TEST-CHAR01-CORRECTION01/RESULT.md` for the
corrected verdict:
  `TEST_CHARACTERIZATION_CORRECTED_TO_SUBSTRATE_AND_DENO_BEHAVIOR`.

This file is preserved as the initial characterization. The corrected
reclassification is:

| target | initial classification | corrected classification |
|---|---|---|
| D1 doctor SIGTERM-respecting | DOCTOR_REPRODUCIBLE_DEFECT | ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL |
| D2 doctor SIGKILL-escalation | DOCTOR_REPRODUCIBLE_DEFECT | ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL |
| A1 extension_quality fmt ANSI | ANSI_REPRODUCIBLE_DEFECT  | DENO_BEHAVIOR_NO_COLOR_NOT_HONORED |
| A2 extension_quality lint ANSI| ANSI_REPRODUCIBLE_DEFECT  | DENO_BEHAVIOR_NO_COLOR_NOT_HONORED |
| 154 mkdir family              | ENVIRONMENTAL            | ENVIRONMENTAL (unchanged) |

The reviewer of this ACT (a subprocess/runtime engineer) identified the
substrate confound: this ACT ran an x86_64 Deno binary under Rosetta on an
arm64 host. CORRECTION01 rules out runtime architecture as a cause by
re-running all experiments under native arm64 Deno, and discovers that
the actual cause of the doctor failures is the VSCodium Helper
`--enable-sandbox` blocking `kill(2)` to descendant processes.

The four BASELINE01-unresolved failures split into two independent reproducible defects:

| target | classification | evidence |
|---|---|---|
| D1 doctor_audit SIGTERM-respecting | `DOCTOR_REPRODUCIBLE_DEFECT` | REPRODUCED_REPEATEDLY (N=5 isolated, N=1 full-suite, N=1 cached-only) |
| D2 doctor_audit SIGKILL-escalation | `DOCTOR_REPRODUCIBLE_DEFECT` | REPRODUCED_REPEATEDLY (N=5 isolated, N=1 full-suite, N=1 cached-only) |
| A1 extension_quality fmt ANSI | `ANSI_REPRODUCIBLE_DEFECT` | REPRODUCED_REPEATEDLY (N=5 isolated, N=1 full-suite, N=1 cached-only, NO_COLOR, TERM=dumb) |
| A2 extension_quality lint ANSI | `ANSI_REPRODUCIBLE_DEFECT` | REPRODUCED_REPEATEDLY (N=5 isolated, N=1 full-suite, N=1 cached-only, NO_COLOR, TERM=dumb) |

```
classified_targets == 4   ✓
```

**SUBJECT**: `bcaa9695b7f27f51964a9f41587fdf112b261c89` (unchanged)

**DENO_VERSION**: `deno 2.9.7 (stable, release, x86_64-apple-darwin)`

---

## PRIMARY MATRIX

| Cell | description | result |
|------|-------------|--------|
| A | real HOME / default DENO_DIR | cannot start — read-only HOME cannot stage JSR cache |
| B | synthetic writable HOME / fresh DENO_DIR / network available | partial full-suite captured (truncated); all 4 unresolved targets FAILED; 154 mkdir family disappeared |
| C | synthetic HOME / warm DENO_DIR | telemetry controls PASS |
| D | synthetic HOME / warm DENO_DIR / --cached-only | PASS for telemetry; doctor + ANSI still fail (defects are not cache-related) |
| E | --reload | not needed — H-CACHE-A falsified by Cell B with fresh DENO_DIR |

---

## BASELINE 154 PermissionDenied

```
BASELINE01 raw:    138 occurrences of
                   "PermissionDenied: Operation not permitted (os error 1):
                   mkdir '/Volumes/UserData/Users/chistyakov/.claude/skills/swamp'"
Cell B (synthetic writable HOME): 0 occurrences of that signature.

Reproduced in A: not measurable — A cannot start.
Present in B:    0 occurrences.
Present in C:    0 occurrences.
Classification:  ENVIRONMENTAL — confirmed deterministic consequence of
                 unwritable $HOME/.claude/skills/swamp.
```

---

## BASELINE 2 telemetry JSR

```
B (fresh DENO_DIR): ok | 2 passed | 0 failed (12s)
C (warm DENO_DIR):  ok | 2 passed | 0 failed (5s)
D (--cached-only):  ok | 2 passed | 0 failed (5s)

Classification: BASELINE_TELEMETRY_FAILURE_NOT_REPRODUCED on this host.
               The BASELINE01 JSR-cache failure remains historical
               environmental evidence per CORRECTION02; the test
               classification of "environmental — JSR manifest/cache
               failure" is plausible but cannot be re-confirmed on a
               host where the cache populates cleanly.
```

---

## DOCTOR

```
Isolated (no --parallel, N=5):
  iter=1 duration_ms=61371  FAILED | 11 passed | 2 failed (1m0s)
  iter=2 duration_ms=61463  FAILED | 11 passed | 2 failed (1m0s)
  iter=3 duration_ms=61495  FAILED | 11 passed | 2 failed (1m0s)
  iter=4 duration_ms=61498  FAILED | 11 passed | 2 failed (1m0s)
  iter=5 duration_ms=61388  FAILED | 11 passed | 2 failed (1m0s)

Failure mode: same two tests fail every iteration:
  - runChildWithAbort: aborting a SIGTERM-respecting child terminates it promptly
    -> Error: expected SIGTERM-responding child to exit promptly; took ~30342ms
  - runChildWithAbort: escalates to SIGKILL when child traps SIGTERM
    -> Error: expected SIGKILL escalation to terminate child; took ~30281ms

Full-suite (Cell B.1): both failures observed.
DENO_JOBS controls: not exhaustively run because parallelism hypothesis
                    is falsified by the 5/5 isolated reproduction.
Classification:      DOCTOR_REPRODUCIBLE_DEFECT.
```

---

## ANSI

```
Isolated non-TTY (N=5):
  iter=1 duration_ms=7118  FAILED | 47 passed | 2 failed (6s)
  iter=2 duration_ms=7133  FAILED | 47 passed | 2 failed (6s)
  iter=3 duration_ms=7136  FAILED | 47 passed | 2 failed (6s)
  iter=4 duration_ms=7128  FAILED | 47 passed | 2 failed (6s)
  iter=5 duration_ms=7133  FAILED | 47 passed | 2 failed (6s)

Environment controls (still failing):
  NO_COLOR=1:            FAILED | 47 passed | 2 failed (6s)
  TERM=dumb:             FAILED | 47 passed | 2 failed (6s)
  --cached-only:         FAILED | 47 passed | 2 failed (6s)

Failure mode:
  - checkExtensionQuality: fmt output contains no ANSI escape codes
    -> AssertionError at line 343: assertEquals(fmtIssue !== undefined, true)
       (fmtIssue is undefined: extension_quality_checker.ts runs `deno fmt
       --check --no-config` on a temp file with NO_COLOR=1 set in env, but
       Deno 2.9.7's fmt still emits ANSI escape bytes to stdout/stderr when
       output is piped.)
  - checkExtensionQuality: lint output contains no ANSI escape codes
    -> Same root cause with `deno lint` instead of `deno fmt`.

Full-suite (Cell B.1): both failures observed.
Classification:        ANSI_REPRODUCIBLE_DEFECT.
```

---

## CACHE

```
Fresh DENO_DIR (Cell B):  19209 files / 288 MB after one full-suite run.
                          Telemetry: 2 passed (12s for cache fill).
Warm DENO_DIR (Cell C):   Same file count, no new downloads.
                          Telemetry: 2 passed (5s).
Cached-only (Cell D):     Telemetry: 2 passed.
                          Doctor + ANSI: still fail (defects not cache-related).
Reload (Cell E):          not run — H-CACHE-A falsified by Cell B with fresh.

Cache status: VERIFIED_PREWARMED (Cell D --cached-only passes for telemetry).

Classification: cache state is independent of the four unresolved failures.
```

---

## CONSERVATION

```
All full-suite arithmetic:    partial Cell B.1 = 12453 ok + 44 FAILED + 31 ignored = 12,528 observed.
                             (Truncated by tool harness SIGTERM; Deno's natural test summary
                              not yet emitted at truncation time.)
Isolated arithmetic:         doctor: 11 + 2 == 13 ✓
                             ansi:   47 + 2 == 49 ✓
                             telemetry: 2 + 0 == 2 ✓
Target classifications:      4 (== 4) ✓
```

---

## EVIDENCE

```
Raw hashes: see .factory/evidence/SWAMP-TEST-CHAR01/MANIFEST.md
BASELINE01 raw hash preserved: ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417  ✓
Authored hygiene:             AUTHORED_ARTIFACTS_DIFF_CHECK = PASS  ✓
Whole-range check:            EXPECTED_FAIL_RAW_EVIDENCE (test.stdout:17650 trailing blank line, by design)
```

---

## PRODUCTION SOURCE CHANGES

```
none
```

`git diff --name-only BASELINE_SUBJECT..ACT_HEAD | grep -v '^\.factory/'` is empty.

---

## RECOMMENDED NEXT ACT

**`ACT-SWAMP-DOCTOR-SIGNAL01`** — repair the `runChildWithAbort` defect
in `src/cli/commands/doctor_audit.ts`. Two doctor tests fail because
`ChildProcess.kill("SIGTERM")` does not actually terminate a child whose
event loop is blocked awaiting a `setTimeout`. The child waits the full
30 seconds. This is a deterministic defect; the test environment is
irrelevant.

(Followed by `ACT-SWAMP-ANSI-OUTPUT01` for the ANSI defect in
`extension_quality_checker.ts`, which does not strip ANSI escape bytes
from `deno fmt --check` / `deno lint` subprocess output, and Deno 2.9.7
emits those bytes even when `NO_COLOR=1` is set in the subprocess env.)

---

## NEGATIVE CLAIMS

```
NO_SWAMP_PRODUCTION_CODE_CHANGED                 = true
NO_BASELINE_RAW_EVIDENCE_MUTATED                 = true
NO_TEST_FAILURE_FIXED_DURING_CHARACTERIZATION    = true
NO_PASS_INFERRED_FROM_SINGLE_RERUN               = true
NO_ENVIRONMENTAL_CLASSIFICATION_WITHOUT_CONTROL  = true
NO_FLAKE_CLASSIFICATION_WITHOUT_REPETITION       = true
NO_RAW_EVIDENCE_NORMALIZED_IN_PLACE              = true
BOARD_STATE_AGREES_WITH_ACT_STATE                = true (this ACT CLOSED at commit; SWAMP-TEST-CHAR01 row updated)
POLICY_EQUALS_VERIFIER_SCOPE_EQUALS_CLAIM        = true
```

---

# END RESULT — ACT-SWAMP-TEST-CHAR01
