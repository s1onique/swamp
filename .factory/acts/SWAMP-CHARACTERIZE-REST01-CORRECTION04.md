# ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION04
# Restore Semantic Predicate Fidelity

## Why this ACT exists

ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION03 (commits f39305ef +
95203ca5) restored closure-state authority under a two-commit
protocol, but a peer review of the closure packet exposed four
remaining semantic-predicate defects. The predicates' NAMES
implied stronger checks than the implementations actually
performed. This violates a doctrine property the review formalized
as **semantic predicate fidelity**:

> The predicate's implementation must prove exactly what its name
> and reported claim say — not a weaker neighboring property.

The four defects:

  D1. `WORKING_TREE_CLEAN_AT_MEASUREMENT=true` was emitted while
      `git status --short` reported eight modified/untracked
      paths. The verifier defined away the attestation-build dirt
      (raw-sha256.txt, build_raw_sha256.sh, POST-COMMIT-ATTESTATION.md,
      epic-board.md, precommit/verifier.*, postcommit/**,
      freeze_postcommit.sh) and called the remainder "clean".
      Git's ordinary definition of clean is non-empty status.
      The predicate name lied.

  D2. ACT/manifest prose repeatedly claimed the raw hash manifest
      had "17 entries" while the committed file had 13 lines. The
      "17" was a stale number from an earlier draft before the
      build script's exclusions were tightened. Projection
      consistency regressed on evidence cardinality.

  D3. `PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED` was emitted
      from the overall verifier verdict:
          [ "$FAIL_COUNT" = 0 ] && echo true || echo false
      so the scalar projected the whole verifier result, not the
      hash equality. If some unrelated predicate had failed while
      the historical parent hash was perfectly preserved, the
      output would have incorrectly said PRESERVED=false.

  D4. `ATTESTATION_SUBJECT_BOUND` was implemented as
          m.get("subject") and m.get("parent_commit")
      which only proves two fields are non-empty. It did NOT
      prove that Commit B attests Commit A:
        - captured head.txt matches Commit A
        - POST-COMMIT-ATTESTATION.CONTENT_COMMIT_SHA matches
        - captured tree.txt matches Commit A's tree
        - POST-COMMIT-ATTESTATION.CONTENT_TREE_SHA matches
        - Commit A is an ancestor of Commit B
        - Commit B contains the captured postcommit artifacts
        - captured verifier.stdout matches what Commit B carries

This ACT repairs those four defects. No canonical classification
changes; no production code changes; no new reproduction; the
two-commit closure protocol is preserved; doctrine is extended
to seven properties (the six from CORRECTION03 plus the new
semantic predicate fidelity).

## Subject (unchanged from CORRECTION03)

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Parent state (frozen from CORRECTION03)

  CLUSTER-01: ENVIRONMENTAL          | SUBSTRATE              | FALSIFIED_BY_CONTROL                | count=31
  CLUSTER-02: UNRESOLVED             | UNKNOWN                | OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD | count= 1
  CLUSTER-03: TEST_CONTRACT_AMBIGUITY| SWAMP_TEST_CONTRACT    | REPRODUCED_REPEATEDLY               | count= 1
  Aggregate:   31+1+1 = 33 = runner_failed; no_unknown_red = false; DOGFOOD_READY = false

  Parent commit of CORRECTION04 = 95203ca5a6efc3bf73bc3ff733fc5b2117b0e4ea
  Parent commit of CORRECTION03 content (the original content commit)
                                  = f39305efe8ab6d03496488a45f0d81f7feca9132
  Parent raw manifest path       = .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
  Parent raw manifest expected SHA
                                  = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
                                  (must still match at Commit C; the CORRECTION03
                                   attestation commit only ADDED postcommit/
                                   artifacts and rebuilt the manifest, did not
                                   touch parent raw manifest.)

## Jobs (four, bounded)

### Job 1 — D1: Rename and redefine the cleanliness predicate

  Rename:
    WORKING_TREE_CLEAN_AT_MEASUREMENT
      → NO_UNEXPECTED_WORKTREE_DIRT_AT_ATTESTATION_CAPTURE

  Add three observable scalars that name what they actually measure:
    RAW_GIT_STATUS_ENTRY_COUNT=<N>            (raw git status --short line count)
    EXPECTED_ATTESTATION_BUILD_DIRT_COUNT=<N> (paths legitimately produced by the
                                               attestation-capture process)
    UNEXPECTED_DIRT_COUNT=<N>                (RAW - EXPECTED)

  Predicate asserts:
    UNEXPECTED_DIRT_COUNT == 0

  The exclusion list is documented in the verifier and reproduced
  in AUTHORITY-MODEL.md. The expected count is derived in the
  verifier itself (so it is not hand-maintained).

### Job 2 — D2: Repair raw evidence cardinality

  Replace every literal "17" claim in current-state prose with
  a derived value:
    raw_sha256_entry_count := $(wc -l < raw-sha256.txt)
                              - $(grep -c '^#\|^$' raw-sha256.txt)

  All prose projections that say "N entries" must be derived from
  the same source. manifest.json gains a `raw_hash_entry_count`
  field populated by the verifier; RESULT/normalized summaries
  quote it as `(raw_hash_entry_count from manifest.json)` rather
  than a hard-coded integer.

### Job 3 — D3: Decouple parent-hash scalar

  PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED must be emitted
  from the actual hash equality check, NOT from overall FAIL_COUNT.

  Refactor:
    PARENT_PRESERVED=true|false    (set at the equality comparison)
    PARENT_RAW_MANIFEST_EXPECTED_SHA256=...
    PARENT_RAW_MANIFEST_ACTUAL_SHA256=...
    PARENT_PRESERVED_SCOPE=PARENT_RAW_MANIFEST    (explicit)

  The verifier-wide VERIFIER_RESULT=PASS|FAIL is independent of
  PARENT_PRESERVED. A negative control (force one unrelated
  predicate to fail, e.g. classification, while the parent hash
  is preserved) must demonstrate:
    VERIFIER_RESULT=FAIL
    PARENT_PRESERVED=true

### Job 4 — D4: Real attestation binding

  ATTESTATION_SUBJECT_BOUND must prove six concrete relations.
  Implement as a single combined check that fails if any one is
  not satisfied:

    a) captured head.txt == expected CONTENT_COMMIT_SHA
       (i.e. the postcommit evidence names the same commit
        we are attesting)
    b) captured tree.txt == `git rev-parse <expected content>^{tree}`
    c) POST-COMMIT-ATTESTATION.md CONTENT_COMMIT_SHA == expected
       CONTENT_COMMIT_SHA
    d) POST-COMMIT-ATTESTATION.md CONTENT_TREE_SHA  == captured tree
    e) expected CONTENT_COMMIT is an ancestor of HEAD
       (the attestation commit is descended from the content commit)
    f) every captured postcommit/* file in Commit B has the
       exact blob hash as the captured version on disk
       (proven via `git ls-tree HEAD -- postcommit/` and sha256sum)

  A negative control mutates the attested CONTENT_COMMIT_SHA in
  POST-COMMIT-ATTESTATION.md and proves ATTESTATION_SUBJECT_BOUND
  fails while the parent-hash predicate still passes.

## Doctrine upgrade

  From six properties (CORRECTION03):
    1. arithmetic consistency
    2. provenance integrity
    3. causal sufficiency
    4. verifier authority
    5. projection consistency
    6. temporal/state binding

  To seven properties (CORRECTION04):
    1. arithmetic consistency
    2. provenance integrity
    3. causal sufficiency
    4. verifier authority
    5. projection consistency
    6. temporal/state binding
    7. semantic predicate fidelity  (NEW)

  Property 7: a predicate's implementation must prove exactly
  what its name says, not a weaker neighboring property.

## Closure protocol

  Commit C (content) — replaces the CORRECTION03 verifier and
  evidence with semantically-faithful equivalents; state in
  epic-board: CLOSED_PENDING_ATTESTATION.

  Commit D (attestation) — captures postcommit evidence against
  Commit C, transitions epic-board to CLOSED.

## Files (this ACT)

  Edited (project-wide):
    .factory/scripts/check_characterize_rest01_correction03.sh
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      MANIFEST.md, RESULT.md, AUTHORITY-MODEL.md, PROJECTION-AUDIT.md,
      POST-COMMIT-ATTESTATION.md, manifest.json, normalized/summary.txt
    .factory/epic-board.md                       (CORRECTION04 row added)
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      raw-sha256.txt                             (regenerated to new count)
      precommit/*                                (re-frozen)
      postcommit/*                               (re-captured at Commit D)

  Unchanged:
    src/  integration/  extensions/  packages/   (no production change)
    deno.json  deno.lock                          (no production change)
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
       (parent raw manifest SHA unchanged at the historical value)

## Recommended next ACT

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01 (cluster-02 bisect).

  Reason: CLUSTER-02 is the sole unknown-red blocker to
  DOGFOOD_READY. CLUSTER-03 is bounded as a test-contract
  ambiguity and does not block dogfood. The seven properties
  are now in force; Swamp itself remains the problem.

  Do not begin that ACT automatically.
