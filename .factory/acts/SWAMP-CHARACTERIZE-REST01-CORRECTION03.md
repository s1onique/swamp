# ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION03
# Restore Closure-State Authority

## Why this ACT exists

ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION02 (commit 19d6d2e0)
restored machine-projection consistency and wrote a verifier that
could fail, but six closure-authority defects remained:

  D1. The parent raw preservation check (formerly
      `BASELINE01_RAW_SHA_PRESERVED`) accepted preservation merely
      because the file exists. That is not provenance verification;
      it cannot detect mutation. The check is also named after a
      different prior ACT.
  D2. The verifier's own cleanliness is post-commit state, but it
      was claimed from inside the same commit. A verifier cannot
      evidence its own post-commit state.
  D3. The projection count is described as "seven authoritative
      projections" while eight are enumerated. The count and the
      list drift.
  D4. The verifier-count projections disagree: the board row says
      `28/28 PASS`; the result/operator packet says `47/47 PASS`.
  D5. Some closure predicates mix pre-commit content validity with
      post-commit repository-state validity (working tree clean,
      HEAD equals closure commit, etc.) into the same invariant
      set.
  D6. CORRECTION02 raw divergence artifacts themselves contain
      expected pre-commit failures, but the packet does not clearly
      distinguish those from the authoritative post-commit result.

This ACT repairs all six without reopening canonical classification,
without new reproduction, and without production code changes. It
introduces:

  - explicit `--mode precommit|postcommit` predicate separation
  - two-commit closure protocol (content commit + attestation commit)
  - independent historical blob comparison for parent hash preservation
  - canonical projection registry derived from a single machine file
  - deterministic machine-readable verifier final lines
  - partitioned raw evidence with explicit EVIDENCE_ROLE markers

## Subject (unchanged from parent correction ACT)

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Parent state (frozen from CORRECTION02)

  CLUSTER-01: ENVIRONMENTAL          | SUBSTRATE              | FALSIFIED_BY_CONTROL                | count=31
  CLUSTER-02: UNRESOLVED             | UNKNOWN                | OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD | count= 1
  CLUSTER-03: TEST_CONTRACT_AMBIGUITY| SWAMP_TEST_CONTRACT    | REPRODUCED_REPEATEDLY               | count= 1
  Aggregate:   31+1+1 = 33 = runner_failed; no_unknown_red = false; DOGFOOD_READY = false

## Closure protocol

  Commit A (content):
    Corrected verifier, manifest.json, RESULT.md, AUTHORITY-MODEL.md,
    PROJECTION-AUDIT.md, normalized/summary.txt, raw evidence tree,
    epic-board row in CLOSED_PENDING_ATTESTATION state.

  Commit B (attestation):
    Populated POST-COMMIT-ATTESTATION.md binding to Commit A,
    postcommit/ raw evidence, epic-board row transitions to CLOSED.

## Jobs

  1.  Author a corrected verifier
      `.factory/scripts/check_characterize_rest01_correction03.sh`
      with explicit `--mode precommit|postcommit`. The postcommit
      mode binds to a content commit SHA supplied by the caller
      (default: parent commit). The verifier emits deterministic
      machine lines (VERIFIER_TOTAL/PASS/FAIL/RESULT and
      PARENT_CHARACTERIZATION_RAW_MANIFEST_*).

  2.  Independent historical-blob comparison
      Replace `BASELINE01_RAW_SHA_PRESERVED` with
      `PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED`. The
      expected SHA is derived from the historical blob pulled via
        git rev-parse 19d6d2e0:.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
        | xargs git cat-file blob
        | sha256sum
      This makes "the verifier can fail" demonstrable by mutating
      one byte and observing the predicate fail with the specific
      name `PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED`.

  3.  Author a canonical projection registry
      `.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/manifest.json`
      contains `authoritative_projections` array. Projection count
      is derived from `len(authoritative_projections)` = 8. No
      hand-maintained `count = 7` / `count = 8` literals.

  4.  Author deterministic verifier-count projections
      No prose file claims `28/28 PASS` or `47/47 PASS` for the
      current verifier. The verifier also detects those exact
      strings in current-state files as failures. Verifier counts
      come from the verifier's own final lines.

  5.  Separate precommit / postcommit predicates
      Precommit invariants: content + authority-bearing projections.
      Postcommit invariants (additional): HEAD == content commit,
      working tree clean, scope factory-only, evidence resolves
      from content commit tree, parent hash still matches.

  6.  Partition raw evidence with explicit roles
      precommit/                 (EVIDENCE_ROLE=PRE_COMMIT_FROZEN)
      parent-hash-negative/      (EVIDENCE_ROLE=NEGATIVE_CONTROL,
                                  EXPECTED_EXIT_NONZERO=true)
      projection-negative/       (EVIDENCE_ROLE=NEGATIVE_CONTROL,
                                  EXPECTED_EXIT_NONZERO=true)
      postcommit/                (EVIDENCE_ROLE=POST_COMMIT_ATTESTATION,
                                  EXPECTED_EXIT=0)

  7.  Demonstrate negative controls
      parent-hash-negative/mutated.txt shows that one-byte mutation
      of the parent raw manifest causes the verifier to FAIL on
      `PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED` (not on a
      working-tree-dirty check).
      projection-negative/mutated.txt shows that injecting
      `CLUSTER-02 evidence_strength = REPRODUCED_REPEATEDLY` causes
      the verifier to FAIL on the specific projection predicate.

## Files (this ACT)

  Edited:
    .factory/epic-board.md  (CORRECTION03 row added; CORRECTION02
                              marked superseded in machine projection)

  Created (Commit A):
    .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION03.md (this file)
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      MANIFEST.md
      RESULT.md
      AUTHORITY-MODEL.md
      PROJECTION-AUDIT.md
      POST-COMMIT-ATTESTATION.md (template; fields filled at Commit B)
      manifest.json
      normalized/summary.txt
    .factory/scripts/check_characterize_rest01_correction03.sh
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      precommit/                  (verifier stdout/stderr/exitcode,
                                   environment.txt; frozen)
      parent-hash-negative/       (setup.sh, run.sh, before.txt,
                                   mutated.txt, restored.txt,
                                   original.txt, mutation.txt,
                                   restore.txt)
      projection-negative/        (setup.sh, run.sh, before.txt,
                                   mutated.txt, restored.txt,
                                   original.failures.json,
                                   inject.txt, restore.txt)
      raw-sha256.txt              (no self-reference; (raw_hash_entry_count from manifest.json))
      build_raw_sha256.sh
      freeze_precommit.sh
      postcommit/                 (empty at Commit A; populated at
                                   Commit B)

  Created (Commit B):
    .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
      POST-COMMIT-ATTESTATION.md  (fields filled)
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/
      head.txt, tree.txt, status.txt,
      verifier.stdout, verifier.stderr, verifier.exitcode,
      verifier.sha256, environment.txt
    .factory/epic-board.md        (CORRECTION03 row state CLOSED)

  Unchanged:
    src/  integration/  extensions/  packages/   (no production change)
    deno.json  deno.lock                          (no production change)
    .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
       (parent raw manifest SHA unchanged: 7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9)

## Factory doctrine upgrade

  From CORRECTION02 (five properties):
    1. arithmetic consistency
    2. provenance integrity
    3. causal sufficiency
    4. verifier authority
    5. projection consistency

  To CORRECTION03 (six properties):
    1. arithmetic consistency
    2. provenance integrity
    3. causal sufficiency
    4. verifier authority
    5. projection consistency
    6. temporal/state binding (NEW)

  Property 6: a claim must be supported by evidence generated
  from a state in which that claim could actually be observed.

  Examples:
    working_tree_clean_at_commit requires evidence after the
    content commit exists (postcommit/ directory).
    commit_sha == X cannot be authoritatively observed before
    X exists.
    verifier passes on committed tree requires running the
    verifier against the committed tree (not the uncommitted
    working tree from which Commit A was authored).

## Recommended next ACT

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01

  Reason: CLUSTER-02 is the sole unknown-red blocker to
  DOGFOOD_READY. CLUSTER-03 is bounded as a test-contract
  ambiguity and does not block dogfood.

  Do not begin that ACT automatically.
