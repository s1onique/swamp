# ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION01

## Goal

Correct three review-discovered inconsistencies in the
SWAMP-CHARACTERIZE-REST01 closure packet WITHOUT touching production
code:

  1. CLUSTER-02 evidence was overclaimed ("REPRODUCED_REPEATEDLY")
     but actually was "observed once under full-suite load, never
     reproduced isolated". Re-run the minimum control
     (DENO_JOBS=1 / 2 / default) to falsify or confirm the
     parallel-load hypothesis. Reclassify as required.

  2. CLUSTER-03 was framed as a "timing edge" but the test code
     itself (30 ms child lifetime, 100 ms abort delay) makes
     `calls.length === 0` the consistent outcome. Reframe as a
     test-contract ambiguity: T8 has two non-equivalent invariants.

  3. DOGFOOD_READY was claimed `false` while every gate the ACT
     itself enumerated passed. Re-derive mechanically against the
     corrected inventory.

## Inputs

- The prior ACT's evidence tree under
  `.factory/tmp/SWAMP-CHARACTERIZE-REST01/`.
- `src/cli/commands/doctor_audit_test.ts` (read-only).
- `integration/remote_execution_test.ts` (read-only).

## Methodology

All reproduction runs are non-production. Strict no-repo-local-scratch:
all temp/cache under `/tmp/swamp-char-rest01-correction01/`. The
parser pipeline from the prior ACT is reused.

## Jobs

### Job 1: Re-classify CLUSTER-02

Run the controlled experiment:

  a. DENO_JOBS=1   (sequential, no parallel pressure)
  b. DENO_JOBS=2   (limited parallel pressure)
  c. DENO_JOBS     (unset = CPU-count default)
  d. Neighborhood co-run: the four subprocess-harness files plus
     resolve_command (the cluster-01 set, the largest user-facing
     file class that exercises the same machinery)

Each run targets the specific test that failed in the prior ACT:
`integration/remote_execution_test.ts` — `enroll over a real socket`.

Reclassification rules:

  - If CLUSTER-02 fails under (a)/(b)/(c) on any run: the
    parallel-load hypothesis is FALSE; treat as timing-sensitive
    and re-run under unchanged DENO_JOBS to look for variance.
  - If CLUSTER-02 fails under (d) but never under (a)/(b)/(c):
    the parallel-load hypothesis is CONFIRMED; reclassify as
    ENVIRONMENTAL with evidence OBSERVED_UNDER_PARALLEL_LOAD and
    cause_owner = SUBSTRATE.
  - If CLUSTER-02 does not reproduce under any of (a)/(b)/(c)/(d):
    set PRIMARY = UNRESOLVED, CAUSE_OWNER = UNKNOWN,
    EVIDENCE = OBSERVED_ONCE, no_unknown_red=false.

### Job 2: Re-frame CLUSTER-03

No production change. Read the test code, the test name, and the
surrounding portable suite to determine which of the two invariants
T8 is actually asserting. Then emit a corrected cluster doc with:

  - the two candidate invariants side by side;
  - the existing assertion's alignment with one of them;
  - the proposed next-ACT family (`SWAMP-DOCTOR-TERMINAL-RACE01`,
    NOT `SWAMP-DOCTOR-PORTABLE-TIMING01`);
  - the explicit acknowledgement that "tighten abort delay" would
    change the scenario and is therefore NOT the recommended
    repair direction.

### Job 3: Re-derive DOGFOOD_READY mechanically

Apply the gate as written against the corrected cluster inventory.
If the inventory is internally consistent and no failure is
classified PROJECT_DEFECT without a bounded follow-up ACT, then
DOGFOOD_READY must evaluate to `true`.

If CLUSTER-02 is unresolved after Job 1, then the gate fails for a
different and defensible reason (`unresolved > 0`), so DOGFOOD_READY
is `false` — but the conclusion is causally earned, not asserted.

## Outputs

- `.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/`
  - MANIFEST.md
  - CLUSTER-SUMMARY.md (corrected)
  - RESULT.md (corrected verdict, corrected DOGFOOD_READY)
  - clusters/CLUSTER-02.md (corrected)
  - clusters/CLUSTER-03.md (reframed)
  - failures.json (corrected)
  - classified-inventory.json (corrected)
  - normalized/summary.txt
- `.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/`
  - raw evidence (run logs, hashes)
- `.factory/scripts/check_characterize_rest01_correction01.sh`
  (verifier)
- `.factory/epic-board.md` (rows)

## Constraints

- No production code changes.
- No repo-local scratch.
- All cache state under
  `/tmp/swamp-char-rest01-correction01/deno`.
- All raw evidence under
  `.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/`.
