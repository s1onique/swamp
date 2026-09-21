#!/usr/bin/env bash
# Projection divergence negative control.
# Inject one canonical-field divergence (CLUSTER-02 evidence_strength)
# and confirm the verifier fails on the specific predicate.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEG_ROOT="/tmp/swamp-c03-projection-negative"
OUT="$SCRIPT_DIR"
if [ ! -d "$NEG_ROOT/repo" ]; then
  bash "$SCRIPT_DIR/setup.sh" >/dev/null
fi
cd "$NEG_ROOT/repo"

run_step() {
  local label="$1" outfile="$2"
  {
    echo "==== projection-negative :: $label ===="
    echo "step_label=$label"
    echo "step_timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "current_parent_sha=$(git rev-parse HEAD)"
    echo "---- verifier stdout/stderr ----"
  } > "$outfile"
  bash .factory/scripts/check_characterize_rest01_correction03.sh --mode precommit >> "$outfile" 2>&1
  local rc=$?
  echo "verifier_exit_code=$rc" >> "$outfile"
  echo "VERIFIER_TOTAL/PASS/FAIL/RESULT: $(grep -E '^VERIFIER_(TOTAL|PASS|FAIL|RESULT)=' $outfile | tr '\n' ' ')" >> "$outfile"
}

# Backup failures.json
cp .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json "$OUT/original.failures.json"

# Step 1: clean baseline
run_step "before" "$OUT/before.txt"

# Step 2: inject divergence
python3 -c "
import json
p = '.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json'
with open(p) as f: d = json.load(f)
for r in d['failures']:
  if r['cluster_id'] == 'CLUSTER-02':
    r['evidence_strength'] = 'REPRODUCED_REPEATEDLY'
    break
with open(p, 'w') as f: json.dump(d, f, indent=2)
"
echo "injection: CLUSTER-02 evidence_strength -> REPRODUCED_REPEATEDLY" > "$OUT/inject.txt"
run_step "mutated" "$OUT/mutated.txt"

# Step 3: restore exactly
cp "$OUT/original.failures.json" .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json
echo "restore: copied original back" > "$OUT/restore.txt"
run_step "restored" "$OUT/restored.txt"
echo "projection-negative :: DONE"
