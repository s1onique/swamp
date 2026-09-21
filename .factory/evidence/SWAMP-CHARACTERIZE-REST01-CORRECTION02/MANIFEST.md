# MANIFEST — SWAMP-CHARACTERIZE-REST01-CORRECTION02

Subject of correction:  a392c49e1c899fbbbbf39bf84d73a8308c048eb6
Parent ACT:             SWAMP-CHARACTERIZE-REST01-CORRECTION01
Parent commit:          dd2ad518 (factory(swamp): correct three
                         inconsistencies in characterize-rest01 closure)
Grandparent ACT:        SWAMP-CHARACTERIZE-REST01
Correction ACT:         SWAMP-CHARACTERIZE-REST01-CORRECTION02
Correction target:      FOUR machine-projection defects in the parent
                        correction ACT, plus a fifth defect in the
                        verifier itself:
                          D1 failures.json F-33 evidence_strength stale
                          D2 failures.json classification_conservation stale
                          D3 classified-inventory.json per-cluster stale
                          D4 unknown_red field ambiguous across files
                          D5 verifier could not fail (unconditional add ok)
                          D6 CLUSTER-03.md overclaim on production code

## Authored artifacts (this ACT)

  .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION02.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION02/MANIFEST.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION02/RESULT.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION02/PROJECTION-AUDIT.md
  .factory/scripts/check_characterize_rest01_correction02.sh

## Edited (parent ACT files, machine projection only)

  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json
    F-33 evidence_strength REPRODUCED_REPEATEDLY → OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
    F-01 cause_owner SWAMP (test contract) → SWAMP_TEST_CONTRACT
    All rows: unknown_red removed
    Top-level classification_conservation recomputed
    Top-level no_unknown_red recomputed
    Top-level unknown_red removed entirely
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/classified-inventory.json
    per-cluster rows rebuilt from failures.json
    unknown_red, unknown_red_explanation removed
    no_unknown_red recomputed
    dogfood_ready_reason re-derived
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/clusters/CLUSTER-03.md
    Narrowed "production code is NOT at fault" → "observed failure is not
    evidence of a production-code failure".
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/manifest.json
    Added prior_correction_act and correction_act_chain.
  .factory/epic-board.md
    Added CORRECTION02 row (CLOSED).
    Marked CORRECTION01 row as superseded in machine projection.

## Raw evidence (this ACT)

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/before.txt
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/inject.txt
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/during.txt
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/restore.txt
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/after.txt
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/aux/run_verifier_at_root.sh
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt

## Hash manifest

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt
  (SHA-256 of every file under .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/)

## Substrate (no new run; same as parent)

  Deno:           deno 2.9.7 (stable, release, aarch64-apple-darwin)
  OS:             Darwin 23.6.0 arm64
  parent scratch: /tmp/swamp-char-rest01-correction01 (cleaned at CORRECTION01 close)

## Constraints

  No production code changes.
  No new reproduction experiment.
  No repo-local scratch.
  Authored evidence only in .factory/evidence/.
  Raw evidence only in .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/.
