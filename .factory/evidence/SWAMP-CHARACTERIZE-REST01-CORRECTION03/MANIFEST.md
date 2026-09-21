# MANIFEST — SWAMP-CHARACTERIZE-REST01-CORRECTION03

Subject of correction:  a392c49e1c899fbbbbf39bf84d73a8308c048eb6
Parent ACT:             SWAMP-CHARACTERIZE-REST01-CORRECTION02
Parent commit:          19d6d2e0 (factory(swamp): restore machine
                         projection and verifier authority)
Correction ACT:         SWAMP-CHARACTERIZE-REST01-CORRECTION03
Correction target:      SIX closure-authority defects remaining in
                        the parent correction ACT:

                          D1  Parent raw preservation check used an
                              existence-only fallback (any file present
                              PASSed). No provenance verification.
                          D2  Verifier could not evidence its own
                              post-commit cleanliness from inside the
                              content commit being attested.
                          D3  Projection cardinality wording
                              inconsistent ("seven" but eight
                              enumerated).
                          D4  Verifier-count projections disagreed
                              (28/28 vs 47/47).
                          D5  Closure predicates mixed pre-commit
                              content validity with post-commit
                              repository-state validity.
                          D6  CORRECTION02 raw divergence artifacts
                              contained expected pre-commit failures
                              but were not distinguished from the
                              authoritative post-commit result.

## Verdict

  CLOSURE_STATE_AUTHORITY_RESTORED

  Achieved by:
    - independent historical blob comparison
    - parent-hash negative control that demonstrably fails
    - projection divergence negative control that demonstrably fails
    - projection cardinality derived from a single machine registry
    - verifier counts derived at runtime; no stale text
    - explicit precommit / postcommit predicate separation
    - two-commit closure protocol (content commit + attestation
      commit)
    - committed-tree evidence captured after the content commit

## Authored artifacts (this ACT)

  .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION03.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/MANIFEST.md (this file)
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/RESULT.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/AUTHORITY-MODEL.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/PROJECTION-AUDIT.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/POST-COMMIT-ATTESTATION.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/manifest.json
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/normalized/summary.txt

## Edited (project-wide)

  .factory/epic-board.md
    Added CORRECTION03 row (initially CLOSED_PENDING_ATTESTATION;
    transitions to CLOSED via the attestation commit).
    Marked CORRECTION02 row as superseded in machine projection.

## Created (project-wide)

  .factory/scripts/check_characterize_rest01_correction03.sh
    The corrected verifier with explicit --mode precommit|postcommit.
    Emits deterministic machine lines:
      VERIFIER_TOTAL / VERIFIER_PASS / VERIFIER_FAIL / VERIFIER_RESULT
      PARENT_CHARACTERIZATION_RAW_MANIFEST_{EXPECTED,ACTUAL,PRESERVED}_SHA256
    Every authority-bearing check has a falsifiable predicate.

## Raw evidence (this ACT)

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
    precommit/                          (verifier stdout/stderr/exitcode,
                                         environment.txt — frozen by
                                         .factory/tmp/.../freeze_precommit.sh)
    parent-hash-negative/               (before, mutated, restored + setup/run
                                         scripts — demonstrates the verifier
                                         fails when the parent manifest is
                                         mutated by one byte)
    projection-negative/                (before, mutated, restored + setup/run
                                         scripts — demonstrates the verifier
                                         fails on canonical-field divergence)
    postcommit/                         (head, status, tree, verifier stdout,
                                         exitcode, sha256 — captured AFTER the
                                         content commit exists)
    raw-sha256.txt                      (no self-reference; 17 entries;
                                         excludes raw-sha256.txt itself,
                                         the build/freeze scripts, and the
                                         verifier stdout/stderr/exitcode files
                                         that change on every run)
    build_raw_sha256.sh
    freeze_precommit.sh

## Hash manifest properties

  RAW_HASH_MANIFEST_SELF_REFERENTIAL=false
  RAW_HASHES_VERIFY=true               (17 verified)
  no_production_code_changed           (verified by
                                         check_characterize_rest01_correction03.sh
                                         between parent commit and HEAD)

## Substrate (no new run; same as parent correction ACTs)

  Deno:           deno 2.9.7 (pinned in .tool-versions)
  OS:             Darwin 23.6.0 arm64
  Subject:        a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Constraints

  No production code changes.
  No new reproduction experiment.
  No full Swamp test suite invocation.
  Factory-only; verifier + evidence + epic-board + authored ACT.
  Two-commit closure protocol: content commit (Commit A) and
  attestation commit (Commit B).