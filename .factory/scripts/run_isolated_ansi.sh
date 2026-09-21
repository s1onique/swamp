#!/usr/bin/env bash
# Run src/domain/extensions/extension_quality_checker_test.ts N times isolated.
# Usage: run_isolated_ansi.sh <N> <out_dir> [deno_bin]
#
# CORRECTION01 (SWAMP-TEST-CHAR01-CORRECTION01): Captures `$?` IMMEDIATELY
# after the deno test command so .exitcode is the authoritative exit code.
set -u
N="${1:-5}"
OUT="${2:-.factory/tmp/SWAMP-TEST-CHAR01/ansi}"
DENO_BIN="${3:-/tmp/deno-bin/deno}"
source .factory/tmp/SWAMP-TEST-CHAR01/doctor/paths.sh

mkdir -p "$OUT"

# Ensure TMPDIR is set to a writable dir independent of cline-mediator temp dirs
export TMPDIR=/tmp

> "$OUT/iterations.txt"
for i in $(seq 1 "$N"); do
  START=$(date +%s%N)
  set +e
  HOME="$TMP_HOME_B" \
  SWAMP_HOME="$TMP_HOME_B/.swamp" \
  DENO_DIR="$TMP_DENO_B" \
  TMPDIR=/tmp \
  SWAMP_NO_TELEMETRY=1 \
  "$DENO_BIN" test \
    --no-check=remote \
    --allow-read --allow-write --allow-env --allow-run --allow-net --allow-sys --allow-ffi \
    src/domain/extensions/extension_quality_checker_test.ts \
    > "$OUT/iter$i.stdout" 2> "$OUT/iter$i.stderr"
  RC=$?
  set -e
  END=$(date +%s%N)
  DUR_MS=$(( (END-START)/1000000 ))
  printf '%s\n' "$RC" > "$OUT/iter$i.exitcode"
  CLEAN=$(sed 's/\x1b\[[0-9;]*m//g' "$OUT/iter$i.stdout" | grep -E '^(FAILED|ok) \|' | tail -1)
  if [[ "$CLEAN" == FAILED* && "$RC" -eq 0 ]]; then
    echo "WARN: summary=FAILED but exit_code=0 (rc=$RC)" | tee -a "$OUT/iterations.txt"
  fi
  echo "iter=$i duration_ms=$DUR_MS exit_code=$RC summary=$CLEAN" | tee -a "$OUT/iterations.txt"
done
