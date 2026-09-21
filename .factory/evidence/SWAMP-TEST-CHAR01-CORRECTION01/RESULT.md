# RESULT — ACT-SWAMP-TEST-CHAR01-CORRECTION01

**ACT**: SWAMP-TEST-CHAR01-CORRECTION01
**VERDICT**: `TEST_CHARACTERIZATION_CORRECTED_TO_SUBSTRATE_AND_DENO_BEHAVIOR`
**SUBJECT**: bcaa9695b7f27f51964a9f41587fdf112b261c89 (unchanged)

## TL;DR

The reviewer of TEST-CHAR01 was right: substrate and experimental authority
mattered more than the original ACT acknowledged. CORRECTION01 produces a
cleaner picture:

| target | prior classification            | corrected classification                |
|--------|----------------------------------|-----------------------------------------|
| D1 doctor SIGTERM-respecting | DOCTOR_REPRODUCIBLE_DEFECT  | ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL     |
| D2 doctor SIGKILL-escalation | DOCTOR_REPRODUCIBLE_DEFECT  | ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL     |
| A1 extension_quality fmt ANSI | ANSI_REPRODUCIBLE_DEFECT  | DENO_BEHAVIOR_NO_COLOR_NOT_HONORED      |
| A2 extension_quality lint ANSI | ANSI_REPRODUCIBLE_DEFECT  | DENO_BEHAVIOR_NO_COLOR_NOT_HONORED      |
| 154 mkdir family             | ENVIRONMENTAL (unchanged)        | ENVIRONMENTAL (unchanged)               |

```
classified_targets == 4   ✓
environmental == 3        ✓
deno_behavior  == 2       ✓ (subset of the 4 — A1/A2 are a Deno behavior,
                             not substrate)
```

(The two A-class entries share the same root cause: Deno 2.9.7 emits ANSI
escape sequences when fmt/lint finds issues, even with NO_COLOR=1 in the
subprocess env and output piped to a non-TTY. They are counted as 2 in the
"targets" total but 1 in the root-cause total.)

## Three bounded goals

1. **Fix the harness exit-code capture** — DONE.
   - `run_isolated_doctor.sh` and `run_isolated_ansi.sh` now use
     `set +e; …; RC=$?; set -e` immediately after the deno test command.
   - The captured `.exitcode` is now authoritative.
   - Doctrine: `reported_test_status agrees with process_exit_code`.

2. **Re-run doctor + ANSI under native aarch64 Deno 2.9.7** — DONE.
   - doctor isolated N=5 on arm64: 5/5 FAILED, exit_code=1, mean 61105 ms
   - ansi   isolated N=5 on arm64: 5/5 FAILED, exit_code=1, mean   378 ms
   - All four targets reproduce on native arm64. Runtime architecture ruled out.

3. **Swamp-free subprocess signal microreproducer** — DONE.
   - 4 cases (M1..M4): SIGTERM/SIGKILL × ChildProcess.kill/Deno.kill
   - Run on both x86_64 and arm64 Deno 2.9.7
   - Result: all 8 cells return `EPERM: Operation not permitted`
   - `deno test --allow-all` probe: `child.kill` AND `Deno.kill` both return EPERM
   - `/bin/sh` probe: `kill -TERM` returns EPERM (host shell cannot signal descendants)
   - Conclusion: the macOS sandbox (VSCodium Helper --enable-sandbox) blocks
     signal delivery to descendant processes. Substrate defect, not code defect.

## Decision tree outcome

The reviewer's decision tree was correctly mapped; the actual outcome was:

```
both x86_64 and arm64 reproduce doctor failure
+ microreproducer shows EPERM on signal delivery on both
+ /bin/sh kill -TERM also returns EPERM
    ↓
doctor: SUBSTRATE defect, not Swamp, not Deno architecture
```

For ANSI:

```
both x86_64 and arm64 reproduce ANSI failure
+ NO_COLOR=1 / TERM=dumb do not change outcome (verified by od -c)
+ microreproducer shows signal behavior unrelated to ANSI output
    ↓
ansi: DENO BEHAVIOR, not substrate, not runtime-architecture
      (Deno 2.9.7 emits ANSI escapes on fmt/lint issues regardless of NO_COLOR)
```

## Doctor reclassification: ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL

The doctor's `runChildWithAbort` calls `child.kill("SIGTERM")` then awaits
`child.output()`. On this host, `child.kill("SIGTERM")` throws EPERM. The
existing `try { … } catch { return; }` swallows the error, the escalation
timer never gets set, and `child.output()` waits for the child to die
naturally. The test's child blocks for 30s, so `child.output()` resolves
after 30s with `exitCode=0`. The test expects `elapsed < 2_000ms` and
fails.

To make the doctor tests pass on this host, the substrate must be changed:
either run from outside the VSCodium Helper sandbox, or use a host that
does not enable the macOS sandbox.

Swamp code is innocent.

## ANSI reclassification: DENO_BEHAVIOR_NO_COLOR_NOT_HONORED

The ANSI test creates a malformed file (`export const x=1;`) and asserts
that `checkExtensionQuality`'s output does not contain `\x1b[`. Deno 2.9.7's
`fmt --check` emits ANSI escape sequences when it finds issues, regardless
of NO_COLOR=1 in the subprocess env. Verified by `od -c` on both runtimes.

This is **not** a Swamp bug. Swamp correctly captures Deno's output. The
test assertion is incompatible with Deno 2.9.7's actual behavior. Fix options:
  (a) Swamp strips ANSI before reporting (`extension_quality_checker.ts` change)
  (b) Test asserts ANSI is present when issue found, absent when not (test change)
  (c) Deno upstream fix

The fix is a code-level change (test or production), but it is **NOT**
substrate-related and **NOT** runtime-architecture-dependent. Both fix (a)
and (b) are within Swamp's control.

## NEW_FAILURE_SURFACE_UNCHARACTERIZED >= 40

The Cell-B partial run in TEST-CHAR01 captured 44 FAILED tests, of which
only 4 were the unresolved targets. The remaining ≥40 failures were not yet
characterized. This is preserved as `NEW_FAILURE_SURFACE_UNCHARACTERIZED >= 40`.

To preserve this, the full test.stdout from BASELINE01 (sha256
`ae420afe…`) remains untouched in `.factory/tmp/native-baseline/test.stdout`,
and the partially-captured raw stdout from Cell B.1 remains in
`.factory/tmp/SWAMP-TEST-CHAR01/B/B.1.stdout`.

## Evidence hygiene

- CORRECTION01 raw evidence: `.factory/tmp/SWAMP-TEST-CHAR01-CORRECTION01/**`
- BASELINE01 raw evidence: `.factory/tmp/native-baseline/test.stdout` — sha256 unchanged (`ae420afe…`)
- TEST-CHAR01 raw evidence: `.factory/tmp/SWAMP-TEST-CHAR01/**` — sha256 unchanged (per MANIFEST.md)
- Authored artifacts (this ACT): `.factory/evidence/SWAMP-TEST-CHAR01-CORRECTION01/**`, `.factory/scripts/{run_isolated_doctor,run_isolated_ansi,signal_microreproducer}.ts`, `.factory/acts/SWAMP-TEST-CHAR01-CORRECTION01.md`, `.factory/epic-board.md`
- Scope check: `git diff --name-only BASELINE_SUBJECT..HEAD | grep -v '^\.factory/'` — empty

## Recommended next ACT

**`ACT-SWAMP-DOCTOR-SIGNAL01`** — there is no Swamp-side fix for the doctor
defect (it's substrate). The recommended follow-up is to either:
  - Acknowledge the doctor tests cannot pass on sandboxed hosts (skip them
    on those hosts), or
  - Update the test harness to relax the elapsed bound when running under
    a known-sandboxed environment (e.g., a `SKIP_SANDBOX_INCOMPATIBLE`
    env var). This is a test-side change.

**`ACT-SWAMP-ANSI-OUTPUT01`** — fix the ANSI defect in
`extension_quality_checker.ts` by stripping ANSI escapes before reporting
(production-side fix), or update the test assertions to match Deno 2.9.7's
actual output (test-side fix). Decision left to the next ACT.

**`ACT-SWAMP-CHARACTERIZE-REST01`** — characterize the remaining ≥40
failures from the Cell-B partial run, to determine which are environmental,
which are real defects, and which can be ignored.

## Files

- ACT: `.factory/acts/SWAMP-TEST-CHAR01-CORRECTION01.md`
- Evidence: `.factory/evidence/SWAMP-TEST-CHAR01-CORRECTION01/{SUBSTRATE.md, MATRIX.md, SIGNAL-MICROREPRODUCER.md, RESULT.md, manifest.json}`
- Raw: `.factory/tmp/SWAMP-TEST-CHAR01-CORRECTION01/{arm64,x86_64}/{doctor,ansi,signal}/...`, `.factory/tmp/SWAMP-TEST-CHAR01-CORRECTION01/SIGNAL-RESULTS.md`
- Scripts: `.factory/scripts/{signal_microreproducer.ts, signal_microreproducer_faithful.ts, run_isolated_doctor.sh, run_isolated_ansi.sh}` (the latter two corrected)
- Board: `.factory/epic-board.md` (this ACT row: ACTIVE → CLOSED)

## Negative claims

```
NO_SWAMP_PRODUCTION_CODE_CHANGED                 = true
NO_BASELINE_RAW_EVIDENCE_MUTATED                 = true
NO_TEST_CHAR01_RAW_EVIDENCE_MUTATED              = true
NO_TEST_FAILURE_FIXED_DURING_CHARACTERIZATION    = true
NO_PASS_INFERRED_FROM_SINGLE_RERUN               = true (5/5 isolated per target)
NO_ENVIRONMENTAL_CLASSIFICATION_WITHOUT_CONTROL  = true (cross-architecture)
NO_FLAKE_CLASSIFICATION_WITHOUT_REPETITION       = true (5/5 identical)
NO_RAW_EVIDENCE_NORMALIZED_IN_PLACE              = true
BOARD_STATE_AGREES_WITH_ACT_STATE                = true
POLICY_EQUALS_VERIFIER_SCOPE_EQUALS_CLAIM        = true
SUBSTRATE_EXPLICITLY_BOUND_TO_VERDICT            = true
```

## Doctrine additions (proposed for AGENTS.md / FACTORY.md)

- **Experimental conclusions are bound not only to source SHA, but also to
  execution substrate.**  Subject really is
  `(source SHA, runtime version, runtime architecture, OS/kernel,
   sandbox profile, experiment configuration)`.
- **Conservation: `reported_test_status agrees with process_exit_code`**.
  Capture `$?` immediately, before any arithmetic or assignment.
- **Sandbox must be probed before signal-delivery experiments** — VSCodium
  Helper's `--enable-sandbox` is invisible to Deno and breaks `kill(2)`.

---

# END RESULT — ACT-SWAMP-TEST-CHAR01-CORRECTION01
