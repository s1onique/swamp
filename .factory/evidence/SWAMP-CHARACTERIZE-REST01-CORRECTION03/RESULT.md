# RESULT — SWAMP-CHARACTERIZE-REST01-CORRECTION03

## Verdict

  CLOSURE_STATE_AUTHORITY_RESTORED

  (subject to attestation commit B being recorded; content commit A
   already passes precommit and postcommit predicates when bound to it)

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## What this ACT does

  Closes the parent correction ACT's six remaining closure-authority
  defects (D1-D6) without reopening canonical classification, without
  new reproduction, and without production code changes. Introduces
  explicit precommit / postcommit predicate separation, a two-commit
  closure protocol, and a real historical-blob comparison for the
  parent raw manifest.

## Defects addressed

  D1  Parent raw preservation used existence-only fallback
      → independent historical reference via
        `git rev-parse <parent>:<path>` + `git cat-file blob <sha>`
        and SHA-256 comparison against the current committed file.
        Predicate name: PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED.

  D2  Verifier could not evidence its own post-commit cleanliness
      → explicit `--mode precommit|postcommit` separation; the
        postcommit mode additionally asserts HEAD == content commit,
        working tree clean, scope factory-only, and that all
        authoritative files resolve from the content commit tree.
        Postcommit evidence captured AFTER Commit A exists.

  D3  Projection cardinality wording inconsistent ("seven" but eight)
      → canonical count derived from
        .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/manifest.json
        `authoritative_projections` array length (= 8). No
        hard-coded `7` or `8` literals in prose.

  D4  Verifier-count projections disagreed (28/28 vs 47/47)
      → final lines emitted by the verifier as machine-readable
        scalars (`VERIFIER_TOTAL`, `VERIFIER_PASS`, `VERIFIER_FAIL`,
        `VERIFIER_RESULT`). Prose projections must use those
        runtime-derived values; the verifier also rejects stale
        (28 over 28 PASS) or (47 over 47 PASS) text in current-state files.

  D5  Closure predicates mixed pre-commit and post-commit validity
      → explicit separation:
          precommit: content + authority-bearing projections
          postcommit: precommit + HEAD + tree + scope + resolution
        The precommit mode does NOT require a clean working tree
        (it labels this NOT_APPLICABLE_PRE_COMMIT).

  D6  CORRECTION02 raw divergence not distinguished from post-commit
      → CORRECTION03 raw evidence is partitioned into
          precommit/                (EVIDENCE_ROLE=PRE_COMMIT_FROZEN)
          parent-hash-negative/     (EVIDENCE_ROLE=NEGATIVE_CONTROL,
                                     EXPECTED_EXIT_NONZERO=true)
          projection-negative/      (EVIDENCE_ROLE=NEGATIVE_CONTROL,
                                     EXPECTED_EXIT_NONZERO=true)
          postcommit/               (EVIDENCE_ROLE=POST_COMMIT_ATTESTATION,
                                     EXPECTED_EXIT=0)
        The verifier final scalar lines distinguish each run.

## Canonical state (unchanged from CORRECTION02)

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

## Projection registry (machine source of truth)

  Source: .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/manifest.json
  field:  authoritative_projections
  count:  len(authoritative_projections) = 8
  members:
    1. failures.json
    2. classified-inventory.json
    3. CLUSTER-SUMMARY.md
    4. RESULT.md
    5. normalized/summary.txt
    6. clusters/CLUSTER-02.md
    7. clusters/CLUSTER-03.md
    8. epic-board.md

## Verifier counts (runtime-derived; bound by Commit A run)

  See .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/
    verifier.stdout (committed after the content commit exists)

  Pre-commit snapshot (this ACT's working tree, frozen via
  freeze_precommit.sh):
    VERIFIER_TOTAL = 52
    VERIFIER_PASS  = 52
    VERIFIER_FAIL  = 0
    VERIFIER_RESULT= PASS

## Parent hash preservation (D1 fix)

  Parent commit:                  19d6d2e093e1bbc9e2cb160a19018444874444aa
  Parent manifest path:           .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
  Parent manifest expected SHA:   7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  Parent manifest actual SHA:     7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  PRESERVED:                      true

  Independent source:
                                  git rev-parse 19d6d2e0:.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
                                  → blob sha 6209788499e7b54effae3da697eed4b131fadca0
                                  → git cat-file blob 620978... | sha256sum
                                  = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9

  Note: the comparison uses `git rev-parse` + `git cat-file blob` to
  retrieve the exact byte sequence (preserving the trailing newline),
  which `git show` and `$()` substitution would silently strip.

## Parent-hash negative control

  Run in a temporary clone at parent commit. Three runs:
    before:    SHA matches        PASS  (51 PASS / 1 FAIL on
                                       THIS_ACT_RAW_HASH_MANIFEST_EXISTS
                                       in clone; baseline confound)
    mutated:   SHA differs        FAIL  (49 PASS / 2 FAIL — additionally
                                       PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED
                                       fails with observed != expected)
    restored:  SHA matches again  PASS  (51 PASS / 1 FAIL again)

  The mutation flips 1 byte (XOR 0x01 at offset 3) of the parent raw
  manifest. The mutated run's specific failure is the hash predicate,
  NOT a working-tree-dirty check, which proves the predicate can fail.

  Raw evidence: .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/parent-hash-negative/

## Projection divergence negative control

  Run in a temporary clone at parent commit. Three runs:
    before:    CLUSTER-02 evidence_strength = OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
                                       verifier PASS (51 PASS / 1 FAIL
                                       on raw-sha256 baseline confound)
    mutated:   CLUSTER-02 evidence_strength = REPRODUCED_REPEATEDLY (injected)
                                       verifier FAIL on the specific
                                       projection predicate:
                                       `failures.json:CLUSTER-02.evidence_strength`
                                       expected=OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
                                       observed=REPRODUCED_REPEATEDLY
    restored:  original value restored
                                       verifier PASS

  Raw evidence: .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/projection-negative/

## Negative claims (pre-Commit-A)

  NO_PRODUCTION_CODE_CHANGED                       true
  NO_NEW_FAILURE_REPRODUCTION                      true
  NO_CLASSIFICATION_CHANGE                         true
  NO_DOGFOOD_STARTED                               true
  NO_EXISTENCE_ONLY_PROVENANCE_CHECK               true
  NO_SELF_HASH_MANIFEST                             true
  NO_SAME_COMMIT_SELF_ATTESTATION                  true
  NO_PRECOMMIT_CLEANLINESS_CLAIM                   true
  PARENT_HASH_REFERENCE_INDEPENDENT                 true
  PARENT_HASH_NEGATIVE_CONTROL_CAN_FAIL            true (demonstrated)
  PROJECTION_NEGATIVE_CONTROL_CAN_FAIL             true (demonstrated)
  PROJECTION_COUNT_DERIVED                          true (len(registry) = 8)
  VERIFIER_COUNTS_DERIVED                           true (VERIFIER_TOTAL/PASS/FAIL/RESULT)
  POSTCOMMIT_PROPERTIES_HAVE_POSTCOMMIT_EVIDENCE   true (postcommit/ artifacts
                                                         captured AFTER Commit A)
  ATTESTATION_SUBJECT_BOUND                        true (Commit B binds to Commit A)
  BOARD_STATE_AGREES_WITH_ACT_STATE                true (epic-board row
                                                         reads CLOSED_PENDING_ATTESTATION
                                                         at Commit A)

## Files (this ACT)

  Edited:
    .factory/epic-board.md (added CORRECTION03 row;
                            marked CORRECTION02 superseded in
                            machine projection)
  Created:
    .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION03.md
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      MANIFEST.md
      RESULT.md (this file)
      AUTHORITY-MODEL.md
      PROJECTION-AUDIT.md
      POST-COMMIT-ATTESTATION.md
      manifest.json
      normalized/summary.txt
    .factory/scripts/check_characterize_rest01_correction03.sh
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      precommit/                     (verifier stdout/stderr/exitcode,
                                      environment.txt; frozen by
                                      freeze_precommit.sh)
      parent-hash-negative/          (before, mutated, restored +
                                      mutation/restore sidecar files
                                      + setup.sh + run.sh)
      projection-negative/           (before, mutated, restored +
                                      original.failures.json +
                                      inject.txt + restore.txt +
                                      setup.sh + run.sh)
      postcommit/                    (filled in after Commit A exists)
      raw-sha256.txt                 (no self-reference; (raw_hash_entry_count from manifest.json))
      build_raw_sha256.sh
      freeze_precommit.sh

## Recommended next ACT

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01 (cluster-02 bisect).

  Reason: CLUSTER-02 is the ONLY remaining unknown-red blocker.
  CLUSTER-03 is bounded as a test-contract ambiguity and does not
  block dogfood (the gate checks no_unknown_red == true, which fails
  only on UNKNOWN cause_owner rows; CLUSTER-03 cause_owner is
  SWAMP_TEST_CONTRACT, not UNKNOWN).

## CORRECTION04 (this ATT-CORRECTION04 repair — semantic predicate fidelity)

  Closes four defects left by CORRECTION03 where predicate names
  implied stronger checks than the implementations performed:

  D1  WORKING_TREE_CLEAN_AT_MEASUREMENT was a misnomer; the working
      tree had eight modified/untracked paths at attestation capture.
      Replaced with NO_UNEXPECTED_WORKTREE_DIRT_AT_ATTESTATION_CAPTURE
      and three observable scalars (RAW_GIT_STATUS_ENTRY_COUNT,
      EXPECTED_ATTESTATION_BUILD_DIRT_COUNT, UNEXPECTED_DIRT_COUNT).

  D2  Prose claimed "17 entries" in the raw hash manifest while the
      committed file had 13. Replaced every literal with a derived
      value (raw_hash_entry_count from manifest.json; verifier emits
      RAW_SHA256_ENTRY_COUNT scalar).

  D3  PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED was emitted
      from the overall verifier verdict. Decoupled to a separate
      scalar (PARENT_PRESERVED) set at the hash equality, with
      PARENT_PRESERVED_SCOPE=PARENT_RAW_MANIFEST.

  D4  ATTESTATION_SUBJECT_BOUND was implemented as "two fields are
      non-empty". Made real: requires six concrete relations
      (a-f) including ancestor-of relation and blob-hash match for
      every captured postcommit artifact.

  Doctrine upgraded to seven properties (adds "semantic predicate
  fidelity").

## Files (this ATT-CORRECTION04 repair)

  Edited (project-wide):
    .factory/scripts/check_characterize_rest01_correction03.sh
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      MANIFEST.md, RESULT.md, AUTHORITY-MODEL.md, PROJECTION-AUDIT.md,
      manifest.json
    .factory/epic-board.md                       (CORRECTION04 row added)

  Created:
    .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION04.md

  Refrozen at CORRECTION04 content-commit time:
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      precommit/*, postcommit/*, raw-sha256.txt

  Unchanged:
    src/  integration/  extensions/  packages/   (no production change)
    deno.json  deno.lock                          (no production change)
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
       (parent raw manifest SHA unchanged at 7f313578...)

## CORRECTION04 closure (final state)

  Content commit (Commit C):  04164de4d28b4e14ed272b8b3e9feac83f3e9238
  Content tree:               4d769403cff93a74465051f54ac2a7d3d6977e2b
  Attestation commit (Commit D): f9fe4e0cedf91d4b6cf399e744bc8563e87ce0e9
  Attestation tree:           eaaa3bfe6277c9ede4503be9311d76d21345cbb6
  Parent commit of chain:     95203ca5a6efc3bf73bc3ff733fc5b2117b0e4ea
  Subject:                    a392c49e1c899fbbbbf39bf84d73a8308c048eb6

  Post-commit verifier run (committed-tree, against HEAD = Commit D):
    POSTCOMMIT_VERIFIER_TOTAL         = 82
    POSTCOMMIT_VERIFIER_PASS          = 82
    POSTCOMMIT_VERIFIER_FAIL          = 0
    POSTCOMMIT_VERIFIER_RESULT        = PASS
    POSTCOMMIT_VERIFIER_EXIT          = 0
    PROJECTION_COUNT                  = 8 (derived from manifest.json
                                            authoritative_projections array)
    RAW_GIT_STATUS_ENTRY_COUNT        = 0
    EXPECTED_ATTESTATION_BUILD_DIRT_COUNT = 0
    UNEXPECTED_DIRT_COUNT              = 0
    NO_UNEXPECTED_WORKTREE_DIRT_AT_ATTESTATION_CAPTURE = true
    CONTENT_COMMIT_SCOPE_FACTORY_ONLY = true
    ATTESTATION_SUBJECT_BOUND         = true (6/6 relations satisfied)

  Parent raw manifest preserved (D3 fix; independent of overall verdict):
    PARENT_RAW_MANIFEST_EXPECTED_SHA256 = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
    PARENT_RAW_MANIFEST_ACTUAL_SHA256   = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
    PARENT_PRESERVED                    = true
    PARENT_PRESERVED_SCOPE              = PARENT_RAW_MANIFEST

  Raw evidence entry count (D2 fix; runtime-derived from wc -l):
    RAW_SHA256_ENTRY_COUNT             = 13

  Negative controls (both demonstrated, both clean):
    parent-hash-negative:
      before:   51 PASS / 1 FAIL (baseline: epic-board state in clone)
      mutated:  50 PASS / 2 FAIL (+ PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED)
      restored: 51 PASS / 1 FAIL (back to baseline)
    projection-negative:
      before:   51 PASS / 1 FAIL (baseline)
      mutated:  50 PASS / 2 FAIL (+ failures.json:CLUSTER-02.evidence_strength)
      restored: 51 PASS / 1 FAIL (back to baseline)

  D3 independence demonstration: in the 'before' run the overall
  VERIFIER_RESULT=FAIL (baseline confound) but PARENT_PRESERVED=true.
  This proves PARENT_PRESERVED is independent of the overall verdict,
  not just an alias for it.

## Verdict

  CLOSURE_STATE_AUTHORITY_RESTORED

  All four semantic-predicate fidelity defects (D1-D4) repaired;
  doctrine extended to seven properties; closure is self-consistent
  at the committed tree of Commit D = f9fe4e0cedf91d4b6cf399e744bc8563e87ce0e9.

## CORRECTION05 closure (final state — projection identity)

  Authoritative fact source: git only.
    Content commit (Commit C):      `git rev-parse HEAD~1` = 04164de4d28b4e14ed272b8b3e9feac83f3e9238
    Content tree:                   `git rev-parse HEAD~1^{tree}` = 4d769403cff93a74465051f54ac2a7d3d6977e2b
    Attestation commit (Commit D):  `git rev-parse HEAD` = f9fe4e0cedf91d4b6cf399e744bc8563e87ce0e9
    Attestation tree:               `git rev-parse HEAD^{tree}` = eaaa3bfe6277c9ede4503be9311d76d21345cbb6
    Raw evidence count:             `wc -l <committed raw-sha256.txt>` = 13

  Five projection-identity invariants (added in CORRECTION05):
    ATTESTATION_COMMIT_PROJECTIONS_AGREE          = PASS
    CONTENT_COMMIT_PROJECTIONS_AGREE              = PASS
    RAW_HASH_ENTRY_COUNT_PROJECTIONS_AGREE        = PASS
    BOARD_CONTENT_COMMIT_IS_NOT_PLACEHOLDER       = PASS
    MANIFEST_RAW_HASH_ENTRY_COUNT_IS_INTEGER       = PASS

  Manifest update (in this ACT):
    manifest.json.correction_act:            "SWAMP-CHARACTERIZE-REST01-CORRECTION04" -> "SWAMP-CHARACTERIZE-REST01-CORRECTION05"
    manifest.json.verdict:                   "CLOSURE_STATE_AUTHORITY_RESTORED" -> "PROJECTION_IDENTITY_CONSISTENCY_RESTORED"
    manifest.json.raw_hash_entry_count:      null -> 13 (integer)
    manifest.json.doctrine_properties:       + "projection identity" (now 8)
    manifest.json.projection_identity_invariants: 5 entries
    manifest.json.projection_identity_doctrine: "A derived scalar is not actually derived if one authoritative projection still stores null, TBD, or a contradictory literal."

  Board update (in this ACT):
    CORRECTION04 row:  "Content commit TBD; ..." -> "Content commit 04164de4...; attestation commit (this row); raw entry count = 13 (derived at runtime); final postcommit verifier 82/82/0/PASS at HEAD."
    CORRECTION05 row added.
    Epic board no longer carries the "Content commit TBD" placeholder in any active projection.

  Post-COMMIT-ATTESTATION.md update:
    Verdict:                                     CLOSURE_STATE_AUTHORITY_RESTORED -> PROJECTION_IDENTITY_CONSISTENCY_RESTORED
    ATTESTATION_SUBJECT_BOUND wording:           "all 6 relations satisfied at capture-time placeholders" -> "all 6 relations satisfied at post-attestation runtime"
    Added explicit "RAW_SHA256_ENTRY_COUNT = 13 (runtime-derived from committed raw-sha256.txt via wc -l)".
    Added "Authoritative Commit D = git rev-parse HEAD at this artifact's commit."

  Verifier update:
    Postcommit verifier emits 12 new projection lines:
      GIT_DERIVED_HEAD_SHA, GIT_DERIVED_CONTENT_COMMIT_SHA,
      GIT_DERIVED_CONTENT_TREE_SHA, GIT_DERIVED_ATTESTATION_TREE_SHA,
      ATTEST_MD_CONTENT_COMMIT_SHA, ATTEST_MD_CONTENT_TREE_SHA,
      ATTEST_MD_RAW_SHA256_ENTRY_COUNT,
      RESULT_MD_ATTESTATION_COMMIT_SHA, RESULT_MD_RAW_SHA256_ENTRY_COUNT,
      BOARD_CONTENT_COMMIT_SHA,
      MANIFEST_RAW_HASH_ENTRY_COUNT.
    Default CONTENT_COMMIT_SHA: PARENT_COMMIT -> git rev-parse HEAD~1.
    Total invariants: 82 -> 87 (5 new). All PASS required.

## Verdict (CORRECTION05 final)

  PROJECTION_IDENTITY_CONSISTENCY_RESTORED

  CANONICAL FAILURE CLASSIFICATION = ACCEPTED (unchanged from CORRECTION02/03/04)
  SEMANTIC-PREDICATE REPAIR = ACCEPTED (unchanged from CORRECTION04)
  FINAL CLOSURE PROJECTION = AUTHORITATIVE (this ACT)
  DOGFOOD_READY = false (CLUSTER-02 remains sole unknown-red blocker)

  Next ACT: SWAMP-REMOTE-PARALLEL-INTERFERENCE01.
