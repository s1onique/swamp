# ENVIRONMENT — SWAMP-CHARACTERIZE-REST01-CORRECTION01

## Substrate

  Deno:           deno 2.9.7 (stable, release, aarch64-apple-darwin)
                  at /tmp/deno-arm64/deno (NATIVE arm64)
  OS:             Darwin 23.6.0 arm64 (kernel arch arm64)
  kernel:         Darwin 23.6.0
  HOME:           /tmp/swamp-char-rest01-correction01/home (synthetic writable)
  DENO_DIR:       /tmp/swamp-char-rest01-correction01/deno (external)
  TMPDIR:         /tmp
  PATH:           /tmp/deno-arm64:$PATH
  shell:          zsh 5.9 (ClineMM wrapper, per-command timeout 600s)

## Permissions

  All control runs permitted:
    --allow-read
    --allow-env
    --allow-write
    --allow-net
    --allow-run
    --allow-sys
    --allow-ffi
    --allow-import

  No `--no-check` removed from the workflow; control runs used
  `--no-check` to mirror the parent ACT's runner command
  (`deno task test`) and to keep wall-clock low.

## Prewarm

  See .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/prewarm/.
  Wall-clock per control run was ~4-10s, indicating cache was
  sufficiently warm for repeated runs.

## Reproducibility

  Each control is rerunnable by reading this file and the
  run_command_lines in each control's stdout.txt metadata.
  All raw stdio is preserved under
  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/.

## Cleanup

  /tmp/swamp-char-rest01-correction01/ removed at ACT close
  (cached delta of ~218 MB reclaimed).
