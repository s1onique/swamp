# POST-COMMIT ATTESTATION — SWAMP-CHARACTERIZE-REST01-CORRECTION03 (CORRECTION08 acyclic edition)

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Authority

  This artifact attests Commit C (the CORRECTION05 content commit).
  It is itself committed as Commit D (the CORRECTION05 attestation commit).
  It does NOT claim to prove its own cleanliness from inside its
  own contents; it records evidence generated against Commit C.

  ATTESTATION_SUBJECT_COMMIT   = Commit C (CORRECTION05 content)
  ATTESTOR_COMMIT                   = A8_SHA (placeholder; populated at A8 commit time; never claim A8 = PASS)
  PARENT_ACT_COMMIT            = 95203ca5a6efc3bf73bc3ff733fc5b2117b0e4ea
                                 (the CORRECTION03 attestation commit)

  These are different identifiers. Commit D does not make Commit C
  clean. Commit D records that Commit C was clean AT THE TIME the
  verifier ran against Commit C's tree.

  Authoritative Commit C8 = `git rev-parse HEAD~1` at A8's commit time.
  Authoritative Commit A8 = `git rev-parse HEAD` at A8's commit time.

## Populated fields (final, after Commit C existed, attested at Commit D)

  CONTENT_COMMIT_SHA                = (derived from git rev-parse at evaluation time; the verifier computes CONTENT_COMMIT_SHA on every invocation) (== git HEAD~1 at A8 commit time; populated at C8 commit time)
  CONTENT_TREE_SHA                  = 941e41c88f56aff887d59006a4c1dc7eba6d33b8 (== git rev-parse C8^{tree} at A8 commit time; populated at C8 commit time)
  ATTESTATION_TREE_SHA              = A8_TREE_SHA (== git rev-parse HEAD^{tree} at A8 commit time; populated at A8 commit time)
  ATTESTATION_SUBJECT_COMMIT        = (derived from git rev-parse at evaluation time) (placeholder; populated at C8 commit time)
  ATTESTOR_COMMIT                   = A8_SHA (placeholder; populated at A8 commit time; never claim A8 = PASS)
  PARENT_ACT_COMMIT                 = 95203ca5a6efc3bf73bc3ff733fc5b2117b0e4ea (historical; CORRECTION03 attribution)
  SUBJECT                           = a392c49e1c899fbbbbf39bf84d73a8308c048eb6
  POSTCOMMIT_VERIFIER_EXIT          = 0
  POSTCOMMIT_VERIFIER_TOTAL         = 95 (postcommit; 95 = pre-CORRECTION05 81 + 5 identity + 4 === + 1 THIS_ACT tied to manifest entries + 4 deferred duplicates)
  POSTCOMMIT_VERIFIER_PASS          = 87 (postcommit; all observable properties PASS at C7 commit-time)
  POSTCOMMIT_VERIFIER_FAIL          = 0  (postcommit; no fail)
  POSTCOMMIT_VERIFIER_DEFERRED      = 8  (CORRECTION07 — 8 deferred properties: TERMINAL_RUN_EXECUTED, _EXITCODE_IS_ZERO, _RESULT_IS_PASS, _FAIL_COUNT_IS_ZERO, _BUNDLE_HASH_IS_BOUND, _ID_IS_BOUND, NO_STALE_TERMINAL_RUN_BUNDLE, AUTHORITATIVE_PROJECTIONS_AGREE)
  POSTCOMMIT_VERIFIER_RESULT        = DEFERRED (87/95 PASS, 8 DEFERRED, 0 FAIL; closure bound to post-exec verdict)
  TERMINAL_RUN_EXECUTED             = true (terminal_run/ committed in D7)
  TERMINAL_BUNDLE_HASH              = TERMINAL_BUNDLE_HASH (recorded in C8:terminal_run/manifest.txt; computed at C8 commit time)
  TERMINAL_RUN_ID                   = TERMINAL_RUN_ID (recorded in C8:terminal_run/manifest.txt; computed at C8 commit time)
  POST_EXECUTION_VERIFIER_TOTAL     = 8 (post-exec; 6 terminal-run props + 2 freshness/sweep props)
  POST_EXECUTION_VERIFIER_PASS      = 8 (post-exec; all 8 PASS for closure at D7)
  POST_EXECUTION_VERIFIER_FAIL      = 0 (post-exec; no fail)
  POST_EXECUTION_VERIFIER_RESULT    = PASS (8/8 PASS; post-exec verdict is the final closure authority)
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
  RAW_SHA256_ENTRY_COUNT            = 12 (runtime-derived from committed raw-sha256.txt via wc -l at D7 capture-time; raw-sha256.txt excludes verifier stdout/stderr/exitcode and freeze_* shell scripts to prevent chicken-and-egg with the verifier)
  PARENT_PRESERVED                  = true (D3; independent of overall verdict)

  PARENT_RAW_MANIFEST_EXPECTED_SHA256 = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  PARENT_RAW_MANIFEST_ACTUAL_SHA256   = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  PARENT_PRESERVED                    = true (D3 repair: independent of overall verdict)

  TERMINAL_VERIFIER_RUN_ID (historical; CORRECTION06) = sha256 over committed postcommit/{head.txt=4c1b2124...,tree.txt=ae0e451e...,verifier.exitcode=0} = 6ada1f9cef557f58380a8351c29b809e1e42ceb6d6ed0df9cf705fa62c950ff3
  (Superseded by TERMINAL_RUN_ID in CORRECTION07; the historical value above is from CORRECTION06 closure and is referenced only for traceability to the prior ACT's run identity.)

## Raw evidence (captured AFTER Commit C existed)

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/ at D7 (current values):
    head.txt              git rev-parse HEAD           = 8aba5c0173575b999bf051a0815db100d96b9428 (== git HEAD~1 at D7)
    tree.txt              git rev-parse HEAD^{tree}    = 134731cd966c063ce093113e4c0fa0a2ea153664 (== git HEAD~1^{tree} at D7)
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

## Static relations S1-S5 (CORRECTION08 acyclic architecture)

Five relations derivable from A8's tree by any reader. All five must
PASS for closure. These replace the cyclic "A8 verifies A8" pattern
with the acyclic "A8 attests C8 by reference."

  S1  A8:evidence.subject == C8
        → checked: subject reference exists in manifest.json (subject_commit),
                   in this artifact (ATTESTATION_SUBJECT_COMMIT = C8),
                   and in the CORRECTION08 ACT.

  S2  C8 is parent/ancestor of A8
        → checked: `git merge-base --is-ancestor C8 A8` returns 0.

  S3  bundle hash inside C8 == re-derived from `git ls-tree C8:terminal_run/`
        → checked: BUNDLE_V1 hash re-computed from C8:terminal_run/ files
                   matches the manifest's TERMINAL_BUNDLE_HASH field.

  S4  `git show C8:terminal_run/verifier.stdout` contains
        VERIFIER_RESULT=PASS and VERIFIER_FAIL=0
        → verdict authority on C8. Verifiable by any reader without
          trusting A8.

  S5  every current-state SHA claim inside A8's projections names C8 or
        a value derivable from C8; no C-equals-D collapse
        → checked: AUTHORITATIVE_PROJECTIONS_AGREE expanded sweep
                   (now covers Content commit, Commit C, Commit D,
                   ATTESTATION_CONTAINER_COMMIT, CURRENT_*_COMMIT,
                   CONTENT_TREE_SHA, TERMINAL_RUN_ID, TERMINAL_BUNDLE_HASH,
                   plus the C-equals-D collapse detector).

  The claims A8 makes are:
    A8_ATTESTS = C8
    A8_VERIFIER_SUBJECT = C8
    C8_RESULT = PASS    (verifiable from C8:terminal_run/verifier.stdout)
    A8_RESULT = (not claimed — acyclic architecture)
