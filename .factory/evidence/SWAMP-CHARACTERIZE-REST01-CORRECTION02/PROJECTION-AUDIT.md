# PROJECTION AUDIT — SWAMP-CHARACTERIZE-REST01-CORRECTION02

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Method

  Walk each of the seven authoritative projections
  (failures.json, classified-inventory.json, CLUSTER-SUMMARY.md,
  RESULT.md, normalized/summary.txt, CLUSTER-02.md, CLUSTER-03.md,
  epic-board.md), read each one, and check whether it agrees
  with the canonical machine state. The check is repeated by
  `.factory/scripts/check_characterize_rest01_correction02.sh`.

## Canonical machine state

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
    no_unknown_red        = false
    DOGFOOD_READY         = false (gate blocks on no_unknown_red == true)

## Per-projection agreement

| Projection              | CLUSTER-01 | CLUSTER-02 | CLUSTER-03 | Aggregate |
|-------------------------|------------|------------|------------|-----------|
| failures.json           | OK         | OK         | OK         | OK        |
| classified-inventory    | OK         | OK         | OK         | OK        |
| CLUSTER-SUMMARY.md      | OK         | OK         | OK         | OK        |
| RESULT.md               | OK         | OK         | OK         | OK        |
| normalized/summary.txt  | OK         | OK         | OK         | OK        |
| clusters/CLUSTER-02.md  | n/a        | OK         | n/a        | n/a       |
| clusters/CLUSTER-03.md  | n/a        | n/a        | OK         | n/a       |
| epic-board.md           | OK         | OK         | OK         | OK        |

## Defects addressed

  D1  failures.json F-33 evidence_strength REPRODUCED_REPEATEDLY
      → OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD                     FIXED
  D2  failures.json top-level classification_conservation stale
      → recomputed from failures[] rows (single source of truth) FIXED
  D3  classified-inventory.json per-cluster labels stale
      → rebuilt from failures.json                                 FIXED
  D4  ambiguous unknown_red field (different semantics in two files)
      → removed from both files; only formally defined
        no_unknown_red remains                                     FIXED
  D5  check_characterize_rest01_correction01.sh cannot fail
      → check_characterize_rest01_correction02.sh rewritten
        as predicate→assertion→exit; demonstrated to FAIL
        on intentional divergence (see DIVERGENCE-TEST below)     FIXED
  D6  CLUSTER-03.md "production code is correct" overclaim
      → narrowed to "observed failure is not evidence of a
        production-code failure"                                   FIXED

## DIVERGENCE-TEST (proves D5 fixed)

  Test setup:
    1. Read failures.json F-33 evidence_strength
    2. Save original value
    3. Overwrite to REPRODUCED_REPEATEDLY (the stale value)
    4. Run check_characterize_rest01_correction02.sh
    5. Confirm exit code != 0 and the failing check names F-33
    6. Restore original value
    7. Run verifier again, confirm exit code == 0

  Raw evidence:
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/
      before.txt     (verifier output before divergence)
      inject.txt     (python script that injects divergence)
      during.txt     (verifier output during divergence, MUST fail)
      restore.txt    (python script that restores)
      after.txt      (verifier output after restoration)

  Result:
    before.txt:        45 PASS, 1 FAIL  (only WORKING_TREE pending)
    during.txt:        44 PASS, 2 FAIL  (CLUSTER-02.evidence_strength + WORKING_TREE)
    after.txt:         45 PASS, 1 FAIL  (only WORKING_TREE pending)

  Interpretation: the verifier is now capable of failing
  on a projection divergence. This is the load-bearing
  property for "verifier authority" (Factory doctrine
  property #4). Without this property, the verifier is
  data display, not an assertion.

## Verifier exit-code matrix

  | State                      | exit | summary                |
  |----------------------------|------|------------------------|
  | projections agree          |   0  | 45 PASS, 1 FAIL (tree) |
  | projections diverge (D1)  |   1  | 44 PASS, 2 FAIL        |
  | projections diverge (D3)   |   1  | depends on which proj  |
  | unknown_red re-introduced  |   1  | D4 detector fails      |
  | subject not reachable      |   1  | SUBJECT_REACHABLE fail |
  | production diff non-empty  |   1  | NO_PRODUCTION_CODE...  |

## Negative claims

  NO_PRODUCTION_CODE_CHANGED                  true
  NO_REPO_LOCAL_SCRATCH                       true
  PARENT_RAW_SHA_PRESERVED                    true
  CANONICAL_STATE_PROJECTS_TO_VERIFIER        true
  VERIFIER_CAN_FAIL                           true (demonstrated)
