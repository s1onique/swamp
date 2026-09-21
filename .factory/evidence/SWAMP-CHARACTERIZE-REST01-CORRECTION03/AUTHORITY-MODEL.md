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

## Semantic predicate fidelity (CORRECTION04 — seventh property)

A peer review of CORRECTION03 surfaced four defects where the
predicate's name implied a stronger check than its implementation.
The four defects, repaired in CORRECTION04:

  D1  WORKING_TREE_CLEAN_AT_MEASUREMENT was emitted while
      `git status --short` reported eight modified/untracked paths.
      The verifier had defined away the attestation-build dirt
      (raw-sha256.txt, build_raw_sha256.sh, POST-COMMIT-ATTESTATION.md,
      epic-board.md, precommit/verifier.*, postcommit/**,
      freeze_postcommit.sh) and called the remainder "clean". Git's
      ordinary definition of clean is non-empty status. The
      predicate name lied.

      Repaired: replaced with
        NO_UNEXPECTED_WORKTREE_DIRT_AT_ATTESTATION_CAPTURE
      which asserts the *unexpected* count is zero, and exposes
      the three observable scalars
        RAW_GIT_STATUS_ENTRY_COUNT
        EXPECTED_ATTESTATION_BUILD_DIRT_COUNT
        UNEXPECTED_DIRT_COUNT
      whose names say exactly what they measure.

  D2  ACT/manifest prose claimed "17 entries" while the actual
      committed raw-sha256.txt had 13 lines. The "17" was a stale
      number from a draft before the build script's exclusions
      were tightened. Projection consistency regressed on evidence
      cardinality.

      Repaired: replaced every literal "17" with
        raw_hash_entry_count := (raw-sha256.txt entry count
                                 computed mechanically)
      and the verifier emits the runtime-derived value
        RAW_SHA256_ENTRY_COUNT=<N>
      Prose projections must quote the manifest's raw_hash_entry_count
      (or this scalar) rather than a hard-coded integer.

  D3  PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED was emitted
      from the overall verifier verdict:
          [ "$FAIL_COUNT" = 0 ] && echo true || echo false
      so the scalar projected the whole verifier result, not the
      hash equality.

      Repaired: PARENT_PRESERVED is now set at the hash equality
      comparison and emitted independently of VERIFIER_RESULT. A
      negative control (force one unrelated predicate to fail while
      the parent hash is preserved) demonstrates the two scalars
      are independent. New scalar:
        PARENT_PRESERVED_SCOPE=PARENT_RAW_MANIFEST
      to make the predicate's scope explicit.

  D4  ATTESTATION_SUBJECT_BOUND was implemented as
          m.get("subject") and m.get("parent_commit")
      which only proves two fields are non-empty. It did NOT prove
      that Commit B attests Commit A.

      Repaired: ATTESTATION_SUBJECT_BOUND now requires all six of
        a) captured head.txt matches the bound CONTENT_COMMIT_SHA
        b) captured tree.txt matches `git rev-parse <content>^{tree}`
        c) POST-COMMIT-ATTESTATION.md CONTENT_COMMIT_SHA matches
        d) POST-COMMIT-ATTESTATION.md CONTENT_TREE_SHA matches
        e) the bound content commit is an ancestor of HEAD
        f) every captured postcommit/* blob matches the blob
           committed in HEAD's tree
      The scalar is true iff all six are true. A negative control
      that mutates the attest md's CONTENT_COMMIT_SHA demonstrates
      the predicate fails while parent-hash still passes.

## Property 7 — Semantic predicate fidelity

  A predicate's implementation must prove exactly what its name
  says — not a weaker neighboring property.

  Counter-examples fixed by this ACT:
    WORKING_TREE_CLEAN          != NO_UNEXPECTED_DIRT_AFTER_EXCLUSIONS
    PARENT_HASH_PRESERVED       != WHOLE_VERIFIER_PASSED
    ATTESTATION_SUBJECT_BOUND   != TWO_FIELDS_NONEMPTY
    CONTENT_TREE_SHA_RECORDED   != TREE_OBSERVED  (now BOUND, comparing
                                                  captured to expected)
