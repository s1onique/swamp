# RESULT — SWAMP-CHARACTERIZE-REST01-CORRECTION02

## Verdict

  REMAINING_FAILURE_SURFACE_MIXED  (parent verdict unchanged)
  MACHINE_PROJECTION_AUTHORITY_RESTORED
  VERIFIER_AUTHORITY_RESTORED

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## What this ACT does

  Closes the parent correction ACT's four projection defects
  (D1-D4) plus a fifth projection defect discovered in the
  verifier itself (D5: could not fail). Also narrows the
  CLUSTER-03 wording on production code (D6). No new
  reproduction experiment; factory-only.

## Defects addressed

  D1  failures.json F-33 evidence_strength was stale
      → now OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD.
  D2  failures.json top-level classification_conservation was stale
      → recomputed from failures[] rows.
  D3  classified-inventory.json per-cluster rows were stale
      → rebuilt from failures.json as single source of truth.
  D4  Ambiguous `unknown_red` field (different values across files)
      → removed entirely; only formally defined `no_unknown_red`
        remains.
  D5  Old verifier could not fail (every check called `add ok`
      unconditionally)
      → check_characterize_rest01_correction02.sh rewritten as
        predicate→assertion→exit; demonstrated to FAIL on
        intentional divergence (see DIVERGENCE-TEST below).
  D6  CLUSTER-03.md "production code is NOT at fault" overclaim
      → narrowed to "observed failure is not evidence of a
        production-code failure".

## Canonical state (verified by check_characterize_rest01_correction02.sh)

  CLUSTER-01:
    classification     = ENVIRONMENTAL
    cause_owner        = SUBSTRATE
    evidence_strength  = FALSIFIED_BY_CONTROL
    count              = 31

  CLUSTER-02:
    classification     = UNRESOLVED
    cause_owner        = UNKNOWN
    evidence_strength  = OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
    count              = 1

  CLUSTER-03:
    classification     = TEST_CONTRACT_AMBIGUITY
    cause_owner        = SWAMP_TEST_CONTRACT
    evidence_strength  = REPRODUCED_REPEATEDLY
    count              = 1

  Aggregate:
    classification_counts = {ENVIRONMENTAL:31, UNRESOLVED:1,
                             TEST_CONTRACT_AMBIGUITY:1}
    total                 = 33 = runner_failed
    no_unknown_red        = false  (CLUSTER-02 has UNKNOWN cause_owner)
    DOGFOOD_READY         = false  (gate blocks on no_unknown_red == true)

## Cross-projection agreement (verified)

  | Projection              | Status |
  |-------------------------|--------|
  | failures.json           | agree  |
  | classified-inventory    | agree  |
  | CLUSTER-SUMMARY.md      | agree  |
  | RESULT.md               | agree  |
  | normalized/summary.txt  | agree  |
  | clusters/CLUSTER-02.md  | agree  |
  | clusters/CLUSTER-03.md  | agree  |
  | epic-board.md           | agree  |

  Cross-projection equality for per-cluster classification
  is asserted in the verifier with a separate predicate
  (CROSS_PROJ:CLUSTER-0X.classification).

## Verifier behaviour

  Old verifier (CORRECTION01):
    check_characterize_rest01_correction01.sh
    Every check unconditionally calls `add ok`. Even when
    the observed value disagrees with the expected, the
    script prints PASS and increments SCORE. Cannot fail.

  New verifier (CORRECTION02):
    check_characterize_rest01_correction02.sh
    Each check observes a value, applies a predicate,
    dispatches to pass() or fail() based on the predicate
    result, increments PASS_COUNT or FAIL_COUNT, and exits
    with non-zero status if FAIL_COUNT > 0.

  Demonstrated divergence test:
    State                                | exit | summary
    --------------------------------------|------|----------------
    projections agree (before)            |   1  | 45/1
    projections diverge (CLUSTER-02 D1)   |   1  | 44/2  <- FAIL
    projections agree again (after)       |   1  | 45/1

    (exit 1 in the "agree" rows is WORKING_TREE_CLEAN,
     which is only satisfied at final commit.)

  Raw evidence:
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/
      before.txt, inject.txt, during.txt, restore.txt, after.txt
      run_verifier_at_root.sh

## Factory doctrine upgrade

  From CORRECTION01 (four properties):
    1. arithmetic consistency
    2. provenance integrity
    3. causal sufficiency
    4. verifier authority

  To CORRECTION02 (five properties):
    1. arithmetic consistency
    2. provenance integrity
    3. causal sufficiency
    4. verifier authority
    5. projection consistency  (NEW)

  Property 5 (NEW):
    Every machine-readable state and every prose claim about
    that state must agree. The CORRECTION02 cross-projection
    equality check enforces this for the seven projections
    enumerated above.

  Formal definition:
    projection_consistent := for every cluster c and every
      projection p ∈ {failures.json, classified-inventory.json,
      CLUSTER-SUMMARY.md, RESULT.md, normalized/summary.txt,
      CLUSTER-{c}.md}: projection p reports the same
      classification(c), cause_owner(c), and
      evidence_strength(c).

## Recommended next ACT

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01
    Bisect the full suite to identify the smallest co-running
    test file set that reproduces the 'RPC channel is closed'
    failure at WorkerGateway.dispatch:346. Required to convert
    CLUSTER-02 from UNRESOLVED to a categorized cluster.

  Reason: CLUSTER-02 is the ONLY remaining unknown-red
  blocker. CLUSTER-03 is bounded as a test-contract
  ambiguity and does not block dogfood (the gate checks
  no_unknown_red == true, which fails only on UNKNOWN
  cause_owner rows; CLUSTER-03 cause_owner is
  SWAMP_TEST_CONTRACT, not UNKNOWN).

  SWAMP-DOCTOR-TERMINAL-RACE01 can run in parallel as a
  quality improvement but is not the bottleneck for dogfood.

## Negative claims

  NO_PRODUCTION_CODE_CHANGED                  true
  NO_REPO_LOCAL_SCRATCH                       true
  PARENT_RAW_SHA_PRESERVED                    true
  CANONICAL_STATE_PROJECTS_TO_VERIFIER        true
  VERIFIER_CAN_FAIL                           true (demonstrated)
  WORKING_TREE_CLEAN_AT_FINAL_COMMIT:         pending (this commit)

## Substrate

  Same as parent correction ACT:
    Deno:     deno 2.9.7 (stable, aarch64-apple-darwin)
    OS:       Darwin 23.6.0 arm64
    Scratch:  /tmp/swamp-char-rest01-correction01 (cleaned)

## Files (this ACT)

  Edited:
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/classified-inventory.json
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/clusters/CLUSTER-03.md
    .factory/epic-board.md (added CORRECTION02 row;
                            marked CORRECTION01 superseded in machine projection)
  Created:
    .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION02.md
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION02/RESULT.md (this file)
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION02/PROJECTION-AUDIT.md
    .factory/scripts/check_characterize_rest01_correction02.sh
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/
      before.txt, inject.txt, during.txt, restore.txt, after.txt
      run_verifier_at_root.sh
