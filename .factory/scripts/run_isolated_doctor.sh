#!/usr/bin/env bash
# Run src/cli/commands/doctor_audit_test.ts N times isolated, record outcomes.
# Usage: run_isolated_doctor.sh <N> <out_dir>
set -u
N="${1:-5}"
OUT="${2:-.factory/tmp/SWAMP-TEST-CHAR01/doctor}"
source .factory/tmp/SWAMP-TEST-CHAR01/doctor/paths.sh

mkdir -p "$OUT"

> "$OUT/iterations.txt"
for i in $(seq 1 "$N"); do
  START=$(date +%s%N)
  HOME="$TMP_HOME_B" \
  SWAMP_HOME="$TMP_HOME_B/.swamp" \
  DENO_DIR="$TMP_DENO_B" \
  SWAMP_NO_TELEMETRY=1 \
  /tmp/deno-bin/deno test \
    --no-check=remote \
    --allow-read --allow-write --allow-env --allow-run --allow-net --allow-sys --allow-ffi \
    src/cli/commands/doctor_audit_test.ts \
    > "$OUT/iter$i.stdout" 2> "$OUT/iter$i.stderr"
  END=$(date +%s%N)
  DUR_MS=$(( (END-START)/1000000 ))
  echo $? > "$OUT/iter$i.exitcode"
  CLEAN=$(sed 's/\x1b\[[0-9;]*m//g' "$OUT/iter$i.stdout" | grep -E '^FAILED \|' | tail -1)
  echo "iter=$i duration_ms=$DUR_MS summary=$CLEAN" | tee -a "$OUT/iterations.txt"
done
