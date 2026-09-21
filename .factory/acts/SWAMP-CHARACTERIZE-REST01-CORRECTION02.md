# ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION02
# Restore Machine Projection and Verifier Authority

## Why this ACT exists

ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION01 (commit dd2ad518)
re-classified CLUSTER-02 and CLUSTER-03 in its authored prose
(RESULT.md, CLUSTER-SUMMARY.md, normalized/summary.txt) but
left FOUR projection defects in the machine-readable state:

  D1. failures.json F-33 (CLUSTER-02) still has
      `evidence_strength = REPRODUCED_REPEATEDLY`
      even though the same row has
      `evidence = OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD`
      and `prior_evidence_was = REPRODUCED_REPEATEDLY`.
      The two fields contradict each other.

  D2. failures.json top-level `classification_conservation`
      is stale:
        {PROJECT_DEFECT: 1, ENVIRONMENTAL: 32}
      (the original parent's projection) instead of the
      corrected:
        {ENVIRONMENTAL: 31, UNRESOLVED: 1,
         TEST_CONTRACT_AMBIGUITY: 1}.

  D3. classified-inventory.json per-cluster still labels
      CLUSTER-03 as PROJECT_DEFECT and CLUSTER-02 as
      ENVIRONMENTAL, so the machine projection contradicts
      the authored correction packet.

  D4. Two projection files (failures.json and
      classified-inventory.json) disagree on the meaning of
      `unknown_red` vs `no_unknown_red`:
        failures.json:            unknown_red=False
                                  no_unknown_red=False
        classified-inventory.json:
                                  unknown_red=True
                                  no_unknown_red=False
      The two fields are not formally defined in any
      README or schema; one of them is being used in
      two different ways. Without formal definitions,
      their inclusion is a bug.

  D5. check_characterize_rest01_correction01.sh reports
      PASS for every check, regardless of observed value,
      because every check calls `add ok "..."` which
      unconditionally increments SCORE and prints PASS:.
      This is "data display", not "predicate assertion".
      A verifier that cannot fail is not a verifier.

This ACT addresses all five defects. It introduces no new
reproduction experiment; it is a factory-only restoration of
projection consistency and verifier authority.

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6
  (unchanged from parent correction ACT)

## State at start

  parent correction ACT: dd2ad518 (factory(swamp): correct three inconsistencies...)
  working tree:          clean

## Canonical machine state (target)

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
    no_unknown_red        = false   (CLUSTER-02 has UNKNOWN cause_owner)
    DOGFOOD_READY         = false   (no_unknown_red == false blocks gate)

## Jobs

### Job 1 — Make failures.json canonical and remove unknown_red

  Edit failures.json directly:
    F-33 (CLUSTER-02): evidence_strength →
      OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
    F-01 (CLUSTER-03): cause_owner →
      SWAMP_TEST_CONTRACT  (formally tagged, no prose)
    All rows: drop any `unknown_red` reference.
  Recompute top-level `classification_conservation`
    from the failure[] rows (single source of truth).
  Remove top-level `unknown_red` field entirely.
  Keep top-level `no_unknown_red` field as the formally
    defined predicate:
      no_unknown_red := no failure has cause_owner == UNKNOWN.

### Job 2 — Rebuild classified-inventory.json from failures.json

  The inventory's per-cluster table is the same shape as
  failures.json's per-cluster rows. Rebuild by aggregating
  failures[] and projecting. Remove `unknown_red` field.
  Set `no_unknown_red` from the same predicate.
  Re-derive `cluster_reclassifications.old/new` from
  failures.json rows that have `prior_classification_was`
  and `prior_evidence_was` fields.

### Job 3 — Rewrite verifier with predicate→assertion→exit

  Rewrite .factory/scripts/check_characterize_rest01_correction01.sh:

    1. Define `pass` and `fail` functions that increment
       PASS_COUNT and FAIL_COUNT respectively and print
       `PASS: <name>` / `FAIL: <name> [observed=<obs>]`.
    2. Each check observes a value, applies a predicate
       (bash test / python3 expression), and dispatches
       to pass or fail based on the predicate result.
    3. Add an explicit cross-projection equality check
       between failures.json, classified-inventory.json,
       CLUSTER-SUMMARY.md, RESULT.md, normalized/summary.txt,
       and epic-board.md.
    4. Final exit code: 0 only if FAIL_COUNT == 0.
    5. Demonstrate the verifier can FAIL by injecting a
       divergence and re-running.

### Job 4 — Tighten CLUSTER-03.md wording

  The current phrasing "production code is NOT at fault"
  overclaims. Narrow to:
    "The observed failure is explained by the test
     contract/fixture mismatch. It is not evidence of a
     production-code failure. The production path that
     handles an already-terminated sender has not been
     independently proven correct by this ACT; it is
     merely not implicated by this failure."
  Apply same narrowing to RESULT.md if present.

### Job 5 — Re-derive cluster_reclassifications

  In classified-inventory.json:
    CLUSTER-01: unchanged (no reclassification)
    CLUSTER-02: prior ENVIRONMENTAL/SUBSTRATE/REPRODUCED_REPEATEDLY
                → new UNRESOLVED/UNKNOWN/OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
    CLUSTER-03: prior PROJECT_DEFECT/SWAMP/REPRODUCED_REPEATEDLY
                → new TEST_CONTRACT_AMBIGUITY/SWAMP_TEST_CONTRACT/REPRODUCED_REPEATEDLY

## Files this ACT will touch

  Edited:
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/classified-inventory.json
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/clusters/CLUSTER-03.md
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/RESULT.md (if CLUSTER-03 wording mirrored)
    .factory/scripts/check_characterize_rest01_correction01.sh (rewritten)
    .factory/epic-board.md (added CORRECTION02 row)

  Created:
    .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION02.md (this file)
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION02/RESULT.md
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION02/PROJECTION-AUDIT.md
    .factory/scripts/check_characterize_rest01_correction02.sh
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/ (raw evidence
      for the audit, including the deliberate divergence test)

  Unchanged:
    src/  integration/  extensions/  packages/   (no production change)
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/raw-sha256.txt
       (parent raw evidence SHA unchanged)

## Factory doctrine upgrade

  Evidence validity now requires FIVE independent properties
  (was four in CORRECTION01):

    1. arithmetic consistency
    2. provenance integrity
    3. causal sufficiency
    4. verifier authority
    5. projection consistency  (NEW)

  Property 5: every machine-readable state and every
  prose claim about that state must agree. A claim that
  one projection says X and another says Y is itself
  evidence of insufficient authority, even when each
  projection is internally consistent.

## Recommended next ACT

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01 (cluster-02 bisect).

  Reason: CLUSTER-02 is the only unknown-red item blocking
  dogfood. CLUSTER-03 is now bounded as a test-contract
  ambiguity and does not require SWAMP-DOCTOR-TERMINAL-RACE01
  to resolve before dogfood is unblocked (it can run in
  parallel with REMOTE-PARALLEL-INTERFERENCE01, but is not
  the bottleneck).
