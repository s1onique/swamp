# AUTHORITY-MODEL — SWAMP-CHARACTERIZE-REST01-CORRECTION03

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Layers (bottom up)

  1. OBSERVATION
     Raw test/verifier output. The lowest layer; what the runner
     actually emitted. Examples:
       - .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/*.json
       - .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/*/stdout.txt
       - .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/verifier.stdout

  2. PROJECTION
     Machine-readable summaries derived from observation. Examples:
       - failures.json (per-cluster canonical rows)
       - classified-inventory.json (clusters.* aggregate)
       - normalized/summary.txt
       - CLUSTER-SUMMARY.md

  3. VERIFIER
     Predicates over observations/projections. Examples:
       - check_characterize_rest01_correction03.sh --mode precommit
       - check_characterize_rest01_correction03.sh --mode postcommit

  4. CONTENT COMMIT
     Immutable Git tree containing corrected state, authored evidence,
     verifier, raw evidence. Properties:
       - reachable from HEAD before the attestation commit exists
       - working tree == content commit when the verifier runs
       - no production code touched
       - canonical classification unchanged
       - projection registry has cardinality 8

  5. POST-COMMIT ATTESTATION
     Evidence that the content commit satisfies post-commit predicates:
       - HEAD == content_commit_sha
       - git rev-parse HEAD^{tree} == content_tree_sha
       - working tree clean
       - postcommit verifier exits 0 with 0 FAIL
       - subject reachable
       - scope factory-only
       - evidence files resolve from HEAD tree

  6. ATTESTATION COMMIT
     Immutable container for the post-commit evidence. Properties:
       - records the content_commit_sha it attests
       - records the content_tree_sha it attests
       - commits the .factory/evidence/.../POST-COMMIT-ATTESTATION.md
         plus the postcommit/ raw artifacts
       - does NOT claim to prove its own cleanliness from inside its
         own contents (no recursive self-attestation)

## Authority flow

  observation
    → projection
    → verifier (precommit)
    → content commit (Commit A)
    → post-commit verification (against Commit A's tree)
    → attestation commit (Commit B)

  Each arrow must be:
    - observation recorded as raw evidence (hashed)
    - projection derived deterministically from observation
    - verifier a falsifiable predicate (can FAIL)
    - content commit immutable (recorded in attestation)
    - post-commit verification generated AFTER content commit exists
    - attestation commit a separate immutable container

## Properties of a valid closure

  1. arithmetic consistency
     31 + 1 + 1 = 33 = runner_failed; conservation holds.

  2. provenance integrity
     Every raw evidence file has an independent historical reference;
     the current committed blob matches that reference; the parent
     raw manifest's historical blob matches the current committed
     parent manifest blob.

  3. causal sufficiency
     Each classification has a defended cause_owner. UNKNOWN rows
     are explicitly bounded (e.g. CLUSTER-02's evidence_strength
     = OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD documents why the cause
     owner cannot be assigned).

  4. verifier authority
     Every authority-bearing check has a falsifiable predicate. The
     verifier CAN FAIL. Two negative-control experiments
     demonstrate this:
       parent-hash-negative/mutated.txt   (PARENT preservation fails)
       projection-negative/mutated.txt    (CLUSTER-02 evidence_strength fails)

  5. projection consistency (introduced by CORRECTION02)
     Every authoritative projection reports the same
     classification/cause_owner/evidence_strength/count for each
     cluster. Cross-projection equality enforced in the verifier.

  6. temporal/state binding (introduced by CORRECTION03)
     Every claim is supported by evidence generated from a state in
     which that claim could actually be observed:
       - WORKING_TREE_CLEAN_AT_FINAL_COMMIT is a post-commit claim;
         it requires evidence captured AFTER the content commit
         exists (postcommit/ directory).
       - PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED compares
         against a historical blob pulled from
         `git rev-parse <parent>:<path>`, not against the current
         file (which would be existence-only).
       - The verifier does not assert the content commit is clean
         when the working tree is dirty during authorship.

## Failure semantics

  If any check fails:
    - The verifier exits with non-zero status
    - FAIL: <name> lines name the specific predicate
    - VERIFIER_RESULT=FAIL is emitted
    - The post-commit attestation must NOT be created (no Commit B
      for a failing Commit A)

## Why two commits?

  Post-commit facts require post-commit evidence. A single commit
  cannot authoritatively state "I am clean" because that statement
  is part of the commit itself. The two-commit protocol:

    Commit A   = the corrected state
                 authoritatively supports precommit claims
                 (classifications, projections, parent-hash match)
    Commit B   = post-commit attestation of Commit A
                 authoritatively supports post-commit claims
                 (HEAD == A, working tree clean, scope factory-only,
                  evidence resolves from A's tree)

  Commit B does NOT make Commit A clean. Commit B records that
  Commit A was clean AT THE TIME the verifier ran against
  Commit A's tree. This is a bounded relation:
    ATTESTATION_SUBJECT_COMMIT = Commit A
    ATTESTATION_CONTAINER_COMMIT = Commit B

  The closure of Commit B itself, if needed, would require another
  external authority (or is simply declared by operator judgment
  given the bounded nature of the relation).
