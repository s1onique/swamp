#!/usr/bin/env bash
# parent-hash negative control.
# Critical property: this run script overwrites the per-step output files
# (before.txt, mutated.txt, restored.txt) so they do NOT appear in the
# frozen raw-sha256.txt. Only the sidecar artifacts that are stable
# across reruns (mutation.txt, restore.txt, original.txt) are in the
# manifest.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEG_ROOT="/tmp/swamp-c03-parent-hash-negative"
OUT="$SCRIPT_DIR"
MANIFEST_PATH=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt"
EXPECTED_SHA="7f3135784c1ba38b37b7dd9d7e2365d279f796f93703c0381f79d7d0207ab1c9"

if [ ! -d "$NEG_ROOT/repo" ]; then
  bash "$SCRIPT_DIR/setup.sh" >/dev/null
fi
cd "$NEG_ROOT/repo"

run_step() {
  local label="$1" outfile="$2"
  {
    echo "==== parent-hash-negative :: $label ===="
    echo "step_label=$label"
    echo "step_timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "current_parent_sha=$(git rev-parse HEAD)"
    echo "manifest_path=$MANIFEST_PATH"
    echo "expected_sha256=$EXPECTED_SHA"
    echo "current_actual_sha256=$(sha256sum $MANIFEST_PATH | awk '{print $1}')"
    echo "---- verifier stdout/stderr ----"
  } > "$outfile"
  bash .factory/scripts/check_characterize_rest01_correction03.sh --mode precommit >> "$outfile" 2>&1
  local rc=$?
  echo "verifier_exit_code=$rc" >> "$outfile"
  echo "PRESERVATION_LINE: $(grep -E '^PARENT_CHARACTERIZATION_RAW_MANIFEST_(EXPECTED|ACTUAL|PRESERVED)=' $outfile | tr '\n' ' ')" >> "$outfile"
  echo "VERIFIER_TOTAL/PASS/FAIL/RESULT: $(grep -E '^VERIFIER_(TOTAL|PASS|FAIL|RESULT)=' $outfile | tr '\n' ' ')" >> "$outfile"
}

# Step 1: clean baseline (no mutation)
run_step "before" "$OUT/before.txt"

# Step 2: mutate one byte of the parent raw manifest.
cp "$MANIFEST_PATH" "$OUT/original.txt"
orig=$(sha256sum "$MANIFEST_PATH" | awk '{print $1}')
python3 -c "
import sys
p = '$MANIFEST_PATH'
with open(p, 'rb') as f:
  data = bytearray(f.read())
data[3] ^= 0x01
with open(p, 'wb') as f:
  f.write(data)
"
mutated_sha=$(sha256sum "$MANIFEST_PATH" | awk '{print $1}')
echo "mutation: original=$orig mutated=$mutated_sha" > "$OUT/mutation.txt"

run_step "mutated" "$OUT/mutated.txt"

# Step 3: restore byte-for-byte
cp "$OUT/original.txt" "$MANIFEST_PATH"
restored_sha=$(sha256sum "$MANIFEST_PATH" | awk '{print $1}')
echo "restore: original=$orig restored=$restored_sha equal=$([ "$orig" = "$restored_sha" ] && echo true || echo false)" > "$OUT/restore.txt"

run_step "restored" "$OUT/restored.txt"

echo "parent-hash-negative :: DONE"
