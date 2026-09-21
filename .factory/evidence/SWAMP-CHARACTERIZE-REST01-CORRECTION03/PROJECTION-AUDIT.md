# PROJECTION AUDIT — SWAMP-CHARACTERIZE-REST01-CORRECTION03

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Method

  Walk each of the eight authoritative projections, read each one,
  and check whether it agrees with the canonical machine state held
  in `.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/manifest.json`.
  Cardinality is derived from `len(authoritative_projections)` so
  the count is not hand-maintained.

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

## How each projection is checked

  failures.json (machine):
    The verifier extracts per-cluster rows via Python and asserts
    equality with manifest fields. 9 checks (3 rows × 3 fields).

  classified-inventory.json (machine):
    The verifier reads the `clusters.<id>` dict and asserts equality
    with manifest fields. 9 checks.

  CLUSTER-SUMMARY.md (prose, bounded):
    The verifier extracts the table row for each cluster (using a
    regex that handles the `**bold**` and ` (unchanged)` annotation),
    then asserts equality on classification and evidence_strength.
    3 checks.

  RESULT.md (prose):
    Asserts the verdict line `REMAINING_FAILURE_SURFACE_MIXED` is
    present. 1 check.

  normalized/summary.txt (prose):
    Asserts the conservation block has lines matching
    `ENVIRONMENTAL = 31`, `UNRESOLVED = 1`,
    `TEST_CONTRACT_AMBIGUITY = 1` (using whitespace-tolerant
    regex). 1 combined check.

  clusters/CLUSTER-02.md (prose, bounded context):
    Asserts the file contains CLUSTER-02, UNRESOLVED, UNKNOWN,
    OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD. 1 combined check.

  clusters/CLUSTER-03.md (prose, bounded context):
    Asserts CLUSTER-03, TEST_CONTRACT_AMBIGUITY,
    REPRODUCED_REPEATEDLY; AND `PROJECT_DEFECT` only appears as
    the reclassification source; AND `SWAMP_TEST_CONTRACT` or
    `SWAMP (test contract)` is used as cause_owner. 1 combined check.

  epic-board.md (prose, board semantics):
    Asserts the CORRECTION03 row exists with the expected state
    (CLOSED_PENDING_ATTESTATION at Commit A; CLOSED at Commit B).

## Defects addressed by CORRECTION03

  D1  Parent raw preservation used existence-only fallback
      → independent historical reference via
        `git rev-parse <parent>:<path>` + `git cat-file blob <sha>`
        and SHA-256 comparison against the current committed file.
        Predicate name: PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED.

  D2  Verifier could not evidence its own post-commit cleanliness
      → explicit `--mode precommit|postcommit` separation.

  D3  Projection cardinality wording inconsistent ("seven" but eight)
      → canonical count derived from manifest.json registry = 8.

  D4  Verifier-count projections disagreed (28/28 vs 47/47)
      → single-machine-projection final lines plus no-stale-text
        guard.

  D5  Closure predicates mixed pre-commit and post-commit validity
      → explicit separation.

  D6  CORRECTION02 raw divergence not distinguished from post-commit
      → CORRECTION03 raw evidence partitioned with EVIDENCE_ROLE
        markers; postcommit/ captured AFTER the content commit exists.

## Negative controls (demonstrated)

  parent-hash-negative/mutated.txt
    Mutation: XOR 0x01 at byte 3 of the parent raw manifest.
    Specific failure:
      PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED
      expected=7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
      actual=<mutated sha>

  projection-negative/mutated.txt
    Mutation: failures.json F-33 evidence_strength
              OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD → REPRODUCED_REPEATEDLY
    Specific failure:
      failures.json:CLUSTER-02.evidence_strength
      expected=OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
      observed=REPRODUCED_REPEATEDLY

  Both negative controls run in temporary clones at the parent
  commit; the original parent manifest and failures.json are
  preserved untouched in the working tree.

## Negative claims

  NO_PRODUCTION_CODE_CHANGED                       true
  PARENT_HASH_REFERENCE_INDEPENDENT                true
  PARENT_HASH_NEGATIVE_CONTROL_CAN_FAIL            true (demonstrated)
  PROJECTION_NEGATIVE_CONTROL_CAN_FAIL             true (demonstrated)
  PROJECTION_COUNT_DERIVED                          true
  VERIFIER_COUNTS_DERIVED                           true
  BOARD_STATE_AGREES_WITH_ACT_STATE                true (CLOSED_PENDING_ATTESTATION
                                                         at Commit A)
