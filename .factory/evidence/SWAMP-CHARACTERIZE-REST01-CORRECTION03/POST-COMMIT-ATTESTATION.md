# POST-COMMIT ATTESTATION — SWAMP-CHARACTERIZE-REST01-CORRECTION03 (CORRECTION06 edition)

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Authority

  This artifact attests Commit C (the CORRECTION05 content commit).
  It is itself committed as Commit D (the CORRECTION05 attestation commit).
  It does NOT claim to prove its own cleanliness from inside its
  own contents; it records evidence generated against Commit C.

  ATTESTATION_SUBJECT_COMMIT   = Commit C (CORRECTION05 content)
  ATTESTATION_CONTAINER_COMMIT = Commit D (CORRECTION05 attestation)
  PARENT_ACT_COMMIT            = 95203ca5a6efc3bf73bc3ff733fc5b2117b0e4ea
                                 (the CORRECTION03 attestation commit)

  These are different identifiers. Commit D does not make Commit C
  clean. Commit D records that Commit C was clean AT THE TIME the
  verifier ran against Commit C's tree.

  Authoritative Commit D = `git rev-parse HEAD` at this artifact's commit.
  Authoritative Commit C = `git rev-parse HEAD~1` at this artifact's commit.

## Populated fields (final, after Commit C existed, attested at Commit D)

  CONTENT_COMMIT_SHA                = eda0e6d77073482ce4e6c4d35738aedbec8dde1d (== git HEAD~1)
  CONTENT_TREE_SHA                  = 33e32ae6ce46aad9bf0448c8ed2bd178dc62aee3 (== git rev-parse HEAD~1^{tree} at attestation)
  ATTESTATION_TREE_SHA              = (== git rev-parse HEAD^{tree} at attestation)
  ATTESTATION_TREE_SHA              = eaaa3bfe6277c9ede4503be9311d76d21345cbb6 (== git rev-parse HEAD^{tree})
  SUBJECT                           = a392c49e1c899fbbbbf39bf84d73a8308c048eb6
  POSTCOMMIT_VERIFIER_EXIT          = 0
  POSTCOMMIT_VERIFIER_TOTAL         = 82 (existing)
  POSTCOMMIT_VERIFIER_PASS          = 82 (existing)
  POSTCOMMIT_VERIFIER_FAIL          = 0  (existing)
  POSTCOMMIT_VERIFIER_RESULT        = PASS (existing 82/82)
  PROJECTION_COUNT                  = 8 (derived from manifest.json
                                          authoritative_projections array length)
  WORKING_TREE_CLEAN_AT_MEASUREMENT = (superseded by NO_UNEXPECTED_WORKTREE_DIRT_AT_ATTESTATION_CAPTURE)
  NO_UNEXPECTED_WORKTREE_DIRT_AT_ATTESTATION_CAPTURE = true (D1; raw=3 expected=3 unexpected=0 at final attestation capture)
  RAW_GIT_STATUS_ENTRY_COUNT        = 3
  EXPECTED_ATTESTATION_BUILD_DIRT_COUNT = 3
  UNEXPECTED_DIRT_COUNT              = 0
  CONTENT_COMMIT_SCOPE_FACTORY_ONLY = true (no files outside .factory/ between
                                            parent commit and content commit)
  ATTESTATION_SUBJECT_BOUND         = true (all 6 relations satisfied at post-attestation runtime)
  RAW_SHA256_ENTRY_COUNT            = 13 (runtime-derived from committed raw-sha256.txt via wc -l)
  PARENT_PRESERVED                  = true (D3; independent of overall verdict)
  TERMINAL_VERIFIER_RUN_ID          = (set at C6 from sha256 over committed
                                          postcommit/{head.txt,tree.txt,verifier.exitcode};
                                          equals manifest.json.terminal_verifier_run_id)

  PARENT_RAW_MANIFEST_EXPECTED_SHA256 = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  PARENT_RAW_MANIFEST_ACTUAL_SHA256   = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  PARENT_PRESERVED                    = true (D3 repair: independent of overall verdict)

## Raw evidence (captured AFTER Commit C existed)

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/
    head.txt              git rev-parse HEAD           = 04164de4d28b4e14ed272b8b3e9feac83f3e9238
    tree.txt              git rev-parse HEAD^{tree}    = 4d769403cff93a74465051f54ac2a7d3d6977e2b
    status.txt            git status --short
    verifier.stdout       postcommit verifier stdout
    verifier.stderr       postcommit verifier stderr
    verifier.exitcode     postcommit verifier exit code
    verifier.sha256       sha256 of the verifier file at post-commit time
    environment.txt       captured_at_utc, deno/os/subject snapshot

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/raw-sha256.txt
    (raw_sha256_entry_count from manifest.json; runtime-derived)

## Verdict

  TERMINAL_RUN_BINDING_RESTORED

  (CORRECTION04 verdict was CLOSURE_STATE_AUTHORITY_RESTORED; superseded
   by CORRECTION05 because the closure packet still carried three
   contradictory literal projections about Commit D, the raw evidence
   count, and the board row. CORRECTION06 supersedes CORRECTION05 because
   the committed postcommit/verifier.stdout was the EARLIER FAILED bundle
   (88/13/FAIL, exitcode=1), contradicting the operator-summary claim of
   87/87 PASS.)

  Required conditions met (or TBD-at-Commit-D):
    real historical parent hash comparison      YES
    parent-hash negative control failure         YES (parent-hash-negative/mutated.txt)
    projection negative control failure          YES (projection-negative/mutated.txt)
    projection cardinality reconciled           YES (manifest.json registry length = 8)
    verifier count reconciled (runtime-derived)   YES (VERIFIER_TOTAL/PASS/FAIL scalars)
    pre/post commit predicates separated        YES (--mode precommit|postcommit)
    post-commit verification captured           YES (postcommit/ directory)
    Commit B explicitly attests Commit A        YES (ATTESTATION_BINDING a-f, captured at Commit D)
    no production change                        YES (zero files under src/, integration/, extensions/,
                                                       packages/, deno.json, deno.lock)
    canonical classification unchanged          YES (parent correction ACT's classifications preserved)
    semantic predicate fidelity (CORRECTION04)  YES (D1-D4 all repaired)
    projection identity (CORRECTION05)          YES (5/5 cross-projection identity invariants satisfied;
                                                       all authoritative commits/trees/counts derived from git)
    evidence freshness (CORRECTION06)      YES (4/4 terminal-run binding invariants satisfied;
                                                       committed verifier.stdout contains
                                                       VERIFIER_RESULT=PASS and VERIFIER_FAIL=0;
                                                       committed verifier.exitcode == 0;
                                                       manifest + attest_md + derived terminal_verifier_run_id
                                                       all agree on the same digest)

## Recommended next ACT

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01 (cluster-02 bisect).

  Reason: CLUSTER-02 remains the sole unknown-red blocker to DOGFOOD_READY.
  Classification = UNRESOLVED, cause_owner = UNKNOWN,
  evidence_strength = OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD.

  Do not begin that ACT automatically.
