#!/usr/bin/env bash
# Run src/domain/extensions/extension_quality_checker_test.ts N times isolated.
set -u
N="${1:-5}"
OUT="${2:-.factory/tmp/SWAMP-TEST-CHAR01/ansi}"
source .factory/tmp/SWAMP-TEST-CHAR01/doctor/paths.sh

mkdir -p "$OUT"

# Ensure TMPDIR is set to a writable dir independent of cline-mediator temp dirs
export TMPDIR=/tmp

> "$OUT/iterations.txt"
for i in $(seq 1 "$N"); do
  START=$(date +%s%N)
  HOME="$TMP_HOME_B" \
  SWAMP_HOME="$TMP_HOME_B/.swamp" \
  DENO_DIR="$TMP_DENO_B" \
  TMPDIR=/tmp \
  SWAMP_NO_TELEMETRY=1 \
  /tmp/deno-bin/deno test \
    --no-check=remote \
    --allow-read --allow-write --allow-env --allow-run --allow-net --allow-sys --allow-ffi \
    src/domain/extensions/extension_quality_checker_test.ts \
    > "$OUT/iter$i.stdout" 2> "$OUT/iter$i.stderr"
  END=$(date +%s%N)
  DUR_MS=$(( (END-START)/1000000 ))
  echo $? > "$OUT/iter$i.exitcode"
  CLEAN=$(sed 's/\x1b\[[0-9;]*m//g' "$OUT/iter$i.stdout" | grep -E '^FAILED \|' | tail -1)
  echo "iter=$i duration_ms=$DUR_MS summary=$CLEAN" | tee -a "$OUT/iterations.txt"
done
