# POST-COMMIT ATTESTATION — SWAMP-CHARACTERIZE-REST01-CORRECTION03

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Authority

  This artifact attests Commit A (the content commit).
  It is itself committed as Commit B (the attestation commit).
  It does NOT claim to prove its own cleanliness from inside its
  own contents; it records evidence generated against Commit A.

  ATTESTATION_SUBJECT_COMMIT  = Commit A (the content commit)
  ATTESTATION_CONTAINER_COMMIT = Commit B (this attestation commit)

  These are different identifiers. Commit B does not make Commit A
  clean. Commit B records that Commit A was clean AT THE TIME the
  verifier ran against Commit A's tree.

## Populated fields (after Commit A existed; captured by
##                  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/freeze_postcommit.sh)

  CONTENT_COMMIT_SHA                = f39305efe8ab6d03496488a45f0d81f7feca9132
  CONTENT_TREE_SHA                  = cc6ae00a29a8c082dc1b454f460605d7b17cee86
  ATTESTATION_GENERATED_AT_UTC      = (timestamp captured at postcommit run; see postcommit/environment.txt)
  SUBJECT                           = a392c49e1c899fbbbbf39bf84d73a8308c048eb6
  POSTCOMMIT_VERIFIER_EXIT          = 0
  POSTCOMMIT_VERIFIER_TOTAL         = 69
  POSTCOMMIT_VERIFIER_PASS          = 69
  POSTCOMMIT_VERIFIER_FAIL          = 0
  POSTCOMMIT_VERIFIER_RESULT        = PASS
  PROJECTION_COUNT                  = 8 (derived from manifest.json
                                          authoritative_projections array)
  WORKING_TREE_CLEAN_AT_MEASUREMENT = true (raw=5, considered=1; tracked_dirty=1
                                            for build_raw_sha256.sh which is part
                                            of this attestation commit's content;
                                            cached_dirty=0; other_untracked=0)
  CONTENT_COMMIT_SCOPE_FACTORY_ONLY = true (no files outside .factory/ between
                                            parent commit and content commit)

  PARENT_RAW_MANIFEST_EXPECTED_SHA256 = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  PARENT_RAW_MANIFEST_ACTUAL_SHA256   = 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9
  PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED = true

## Raw evidence (captured AFTER Commit A existed)

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/
    head.txt              git rev-parse HEAD           = f39305efe8ab6d03496488a45f0d81f7feca9132
    tree.txt              git rev-parse HEAD^{tree}    = cc6ae00a29a8c082dc1b454f460605d7b17cee86
    status.txt            git status --short           (raw=5, considered=1; only build_raw_sha256.sh tracked-dirty, which is content for this attestation commit)
    verifier.stdout       postcommit verifier stdout (69 checks PASS)
    verifier.stderr       postcommit verifier stderr
    verifier.exitcode     0
    verifier.sha256       sha256 of the verifier file at post-commit time
    environment.txt       captured_at_utc, deno/os/subject snapshot

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/raw-sha256.txt
    13 entries (covers precommit/, parent-hash-negative/, projection-negative/,
    postcommit/ — excludes the manifest itself, the build/freeze scripts,
    the verifier stdout/stderr/exitcode files that change on every run, and
    environment.txt / status.txt which are run-tied)

## Verdict

  CLOSURE_STATE_AUTHORITY_RESTORED

  Required conditions met:
    real historical parent hash comparison     YES
    hash negative control demonstrates failure YES (parent-hash-negative/mutated.txt)
    projection negative control demonstrates failure YES (projection-negative/mutated.txt)
    projection cardinality reconciled          YES (manifest.json registry length = 8)
    verifier count reconciled                  YES (VERIFIER_TOTAL=69, VERIFIER_PASS=69, VERIFIER_FAIL=0)
    pre/post commit predicates separated       YES (--mode precommit|postcommit)
    post-commit verification captured          YES (postcommit/ directory)
    Commit B explicitly attests Commit A       YES (CONTENT_COMMIT_SHA above)
    no production change                       YES (zero files under src/, integration/, extensions/, packages/, deno.json, deno.lock)
    canonical classification unchanged         YES (parent correction ACT's classifications preserved)

## Recommended next ACT

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01 (cluster-02 bisect).

  Reason: CLUSTER-02 remains the sole unknown-red blocker to DOGFOOD_READY.
  Classification = UNRESOLVED, cause_owner = UNKNOWN,
  evidence_strength = OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD.

  Do not begin that ACT automatically.
