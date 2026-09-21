# MANIFEST — SWAMP-CHARACTERIZE-REST01-CORRECTION01

Subject of correction:  a392c49e1c899fbbbbf39bf84d73a8308c048eb6
Parent ACT:             SWAMP-CHARACTERIZE-REST01
Parent commit:          10d7ccae (factory(swamp): characterize
                         remaining test-suite failures)
Correction ACT:         SWAMP-CHARACTERIZE-REST01-CORRECTION01
Correction target:      three review-discovered inconsistencies in the
                        closure packet:
                          1. CLUSTER-02 evidence overstated
                          2. CLUSTER-03 framed as timing edge
                          3. DOGFOOD_READY false despite gate satisfaction

## Authored artifacts

  .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION01.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/MANIFEST.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/RESULT.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/CLUSTER-SUMMARY.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/ENVIRONMENT.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/manifest.json
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/normalized/summary.txt
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/clusters/CLUSTER-02.md
  .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/clusters/CLUSTER-03.md
  .factory/scripts/check_characterize_rest01_correction01.sh
  .factory/epic-board.md (updated row)

## Raw evidence (correction ACT)

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/prewarm/{stdout.txt,stderr.txt,command.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-jobs1/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-jobs2/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-jobsdefault/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-parallel-r2/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-parallel-r3/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-cluster01/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-cluster01-r2/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-cluster01-r3/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-worker-class/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/integration-co-run/{stdout.txt,stderr.txt}
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/classified-inventory.json

## Referenced but unchanged raw evidence

  .factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stdout (primary run)
  .factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stderr (primary run)
  .factory/tmp/SWAMP-CHARACTERIZE-REST01/raw-sha256.txt
  .factory/tmp/SWAMP-CHARACTERIZE-REST01/clusters/CLUSTER-01/
    isolation-with-deno-on-path.stdout
  .factory/tmp/SWAMP-CHARACTERIZE-REST01/clusters/CLUSTER-02/
    isolation.stdout
  .factory/tmp/SWAMP-CHARACTERIZE-REST01/clusters/CLUSTER-03/
    isolation.stdout

## Hash manifest

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/raw-sha256.txt
  (generated at closure; SHA-256 of every raw evidence file above)

## Substrate

  Deno:           deno 2.9.7 (stable, release, aarch64-apple-darwin)
                  at /tmp/deno-arm64/deno (NATIVE arm64)
  OS:             Darwin 23.6.0 arm64
  HOME:           /tmp/swamp-char-rest01-correction01/home
  DENO_DIR:       /tmp/swamp-char-rest01-correction01/deno
  TMPDIR:         /tmp
  PATH:           /tmp/deno-arm64:$PATH
  cleanup:        /tmp/swamp-char-rest01-correction01 removed at ACT close

## Constraints

  No production code changes.
  No repo-local scratch.
  Authored evidence only in .factory/evidence/.
  Raw evidence only in .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/.
