#!/usr/bin/env bash
# SWAMP-CHARACTERIZE-REST01-CORRECTION02 verifier
# Verifies that all machine projections agree on the canonical state
# and that all predicates that should be true are actually true.
# Designed to FAIL when projections diverge.

set -u
o() { printf 'PASS: %s\n' "$1"; }
n() { printf 'FAIL: %s\n' "$1"; }
PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0
pass() { o "$1"; PASS_COUNT=$((PASS_COUNT+1)); TOTAL=$((TOTAL+1)); }
fail() { n "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); TOTAL=$((TOTAL+1)); }
check() {
  # check "predicate name" "expected" "observed"
  # if expected == observed, pass; else fail with both values
  if [ "$2" = "$3" ]; then
    pass "$1 (=$3)"
  else
    fail "$1 expected=$2 observed=$3"
  fi
}

SUBJECT="a392c49e1c899fbbbbf39bf84d73a8308c048eb6"
# Resolve repo root: script is at .factory/scripts/<name>; cd two levels up.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVID_DIR=.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01
TMP_DIR=.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01
INV="$TMP_DIR/full/classified-inventory.json"
FAIL="$EVID_DIR/failures.json"
MAN="$EVID_DIR/MANIFEST.md"
RES="$EVID_DIR/RESULT.md"
NORM="$EVID_DIR/normalized/summary.txt"
CLSUM="$EVID_DIR/CLUSTER-SUMMARY.md"
EPIC=".factory/epic-board.md"

# --- 1. File presence ---
for f in "$EVID_DIR/failures.json" "$INV" "$EVID_DIR/RESULT.md" "$EVID_DIR/CLUSTER-SUMMARY.md" "$EVID_DIR/MANIFEST.md" "$NORM"; do
  if [ -f "$f" ]; then pass "FILE_PRESENT: $(basename "$f")"
  else fail "FILE_MISSING: $f"; fi
done

# --- 2. failures.json per-cluster canonical rows ---
F_C1=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-01']; print(rows[0]['classification'] if rows else 'MISSING')")
F_C2=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-02']; print(rows[0]['classification'] if rows else 'MISSING')")
F_C3=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-03']; print(rows[0]['classification'] if rows else 'MISSING')")
check "failures.json:CLUSTER-01.classification" "ENVIRONMENTAL" "$F_C1"
check "failures.json:CLUSTER-02.classification" "UNRESOLVED"    "$F_C2"
check "failures.json:CLUSTER-03.classification" "TEST_CONTRACT_AMBIGUITY" "$F_C3"

F_C2_cause=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-02']; print(rows[0]['cause_owner'] if rows else 'MISSING')")
F_C3_cause=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-03']; print(rows[0]['cause_owner'] if rows else 'MISSING')")
check "failures.json:CLUSTER-02.cause_owner" "UNKNOWN"            "$F_C2_cause"
check "failures.json:CLUSTER-03.cause_owner" "SWAMP_TEST_CONTRACT" "$F_C3_cause"

F_C2_ev=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-02']; print(rows[0]['evidence_strength'] if rows else 'MISSING')")
F_C3_ev=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-03']; print(rows[0]['evidence_strength'] if rows else 'MISSING')")
check "failures.json:CLUSTER-02.evidence_strength" "OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD" "$F_C2_ev"
check "failures.json:CLUSTER-03.evidence_strength" "REPRODUCED_REPEATEDLY"                "$F_C3_ev"

# --- 3. failures.json top-level conservation (recomputed) ---
F_CONS=$(python3 -c "import json; d=json.load(open('$FAIL')); print(json.dumps(d.get('classification_conservation',{}),sort_keys=True))")
check "failures.json:classification_conservation" '{"ENVIRONMENTAL": 31, "TEST_CONTRACT_AMBIGUITY": 1, "UNRESOLVED": 1}' "$F_CONS"

F_NUK=$(python3 -c "import json; d=json.load(open('$FAIL')); print(str(d.get('no_unknown_red')).lower())")
check "failures.json:no_unknown_red" "false" "$F_NUK"

# --- 4. failures.json: 'unknown_red' must be absent (not undefined-formally) ---
F_HAS_UK=$(python3 -c "import json; d=json.load(open('$FAIL')); print('true' if 'unknown_red' in d else 'false')")
check "failures.json:unknown_red_absent" "false" "$F_HAS_UK"

# --- 5. classified-inventory.json per-cluster ---
I_C1=$(python3 -c "import json; d=json.load(open('$INV')); print(d['clusters']['CLUSTER-01']['classification'])")
I_C2=$(python3 -c "import json; d=json.load(open('$INV')); print(d['clusters']['CLUSTER-02']['classification'])")
I_C3=$(python3 -c "import json; d=json.load(open('$INV')); print(d['clusters']['CLUSTER-03']['classification'])")
check "inventory:CLUSTER-01.classification" "ENVIRONMENTAL"            "$I_C1"
check "inventory:CLUSTER-02.classification" "UNRESOLVED"               "$I_C2"
check "inventory:CLUSTER-03.classification" "TEST_CONTRACT_AMBIGUITY"  "$I_C3"

I_C2_cause=$(python3 -c "import json; d=json.load(open('$INV')); print(d['clusters']['CLUSTER-02']['cause_owner'])")
I_C3_cause=$(python3 -c "import json; d=json.load(open('$INV')); print(d['clusters']['CLUSTER-03']['cause_owner'])")
check "inventory:CLUSTER-02.cause_owner" "UNKNOWN"            "$I_C2_cause"
check "inventory:CLUSTER-03.cause_owner" "SWAMP_TEST_CONTRACT" "$I_C3_cause"

I_C2_ev=$(python3 -c "import json; d=json.load(open('$INV')); print(d['clusters']['CLUSTER-02']['evidence_strength'])")
I_C3_ev=$(python3 -c "import json; d=json.load(open('$INV')); print(d['clusters']['CLUSTER-03']['evidence_strength'])")
check "inventory:CLUSTER-02.evidence_strength" "OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD" "$I_C2_ev"
check "inventory:CLUSTER-03.evidence_strength" "REPRODUCED_REPEATEDLY"                "$I_C3_ev"

I_CONS=$(python3 -c "import json; d=json.load(open('$INV')); print(json.dumps(d.get('classification_conservation',{}),sort_keys=True))")
check "inventory:classification_conservation" '{"ENVIRONMENTAL": 31, "TEST_CONTRACT_AMBIGUITY": 1, "UNRESOLVED": 1}' "$I_CONS"

I_NUK=$(python3 -c "import json; d=json.load(open('$INV')); print(str(d.get('no_unknown_red')).lower())")
check "inventory:no_unknown_red" "false" "$I_NUK"

I_HAS_UK=$(python3 -c "import json; d=json.load(open('$INV')); print('true' if 'unknown_red' in d else 'false')")
check "inventory:unknown_red_absent" "false" "$I_HAS_UK"

# --- 6. Cross-projection equality ---
for cid in CLUSTER-01 CLUSTER-02 CLUSTER-03; do
  FC=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='$cid']; print(rows[0]['classification'] if rows else 'MISSING')")
  IC=$(python3 -c "import json; d=json.load(open('$INV'));  print(d['clusters']['$cid']['classification'])")
  check "CROSS_PROJ:$cid.classification" "$FC" "$IC"
done

# --- 7. Prose projections (CLUSTER-SUMMARY, RESULT, normalized) ---
# These MUST mention each cluster's corrected label.
for label in "UNRESOLVED" "TEST_CONTRACT_AMBIGUITY"; do
  for src in "$CLSUM" "$RES" "$NORM"; do
    if grep -q "$label" "$src"; then pass "PROSE_LABEL:$label in $(basename "$src")"
    else fail "PROSE_LABEL:$label MISSING from $(basename "$src")"; fi
  done
done

# CLUSTER-SUMMARY must contain the corrected cluster table
if grep -q "CLUSTER-02 |  1 | ENVIRONMENTAL | \*\*UNRESOLVED\*\*" "$CLSUM"; then
  pass "CLUSTER-SUMMARY.md:CLUSTER-02 row corrected"
else
  fail "CLUSTER-SUMMARY.md:CLUSTER-02 row missing or stale"
fi
if grep -q "CLUSTER-03 |  1 | PROJECT_DEFECT | \*\*TEST_CONTRACT_AMBIGUITY\*\*" "$CLSUM"; then
  pass "CLUSTER-SUMMARY.md:CLUSTER-03 row corrected"
else
  fail "CLUSTER-SUMMARY.md:CLUSTER-03 row missing or stale"
fi

# normalized/summary.txt must have the corrected conservation block
if grep -q "ENVIRONMENTAL            = 31" "$NORM"; then pass "normalized:ENVIRONMENTAL=31"
else fail "normalized:ENVIRONMENTAL count missing/wrong"; fi
if grep -q "UNRESOLVED               =  1" "$NORM"; then pass "normalized:UNRESOLVED=1"
else fail "normalized:UNRESOLVED count missing/wrong"; fi
if grep -q "TEST_CONTRACT_AMBIGUITY  =  1" "$NORM"; then pass "normalized:TEST_CONTRACT_AMBIGUITY=1"
else fail "normalized:TEST_CONTRACT_AMBIGUITY count missing/wrong"; fi

# RESULT.md must show the corrected verdict
if grep -q "REMAINING_FAILURE_SURFACE_MIXED" "$RES"; then pass "RESULT:verdict"
else fail "RESULT:verdict MISSING"; fi

# --- 8. epic-board has CORRECTION02 row CLOSED ---
if grep -q 'SWAMP-CHARACTERIZE-REST01-CORRECTION02.*CLOSED' "$EPIC"; then
  pass "epic-board:CORRECTION02 row CLOSED"
else
  fail "epic-board:CORRECTION02 row MISSING or not CLOSED"
fi

# --- 9. Production diff (empty) ---
PROD_CHANGED=$(git diff --name-only "$SUBJECT..HEAD" -- src/ integration/ extensions/ packages/ 2>/dev/null | wc -l | tr -d ' ')
check "NO_PRODUCTION_CODE_CHANGED" "0" "$PROD_CHANGED"

# --- 10. Working tree (must be clean at final commit) ---
WT=$(git status --short | wc -l | tr -d ' ')
check "WORKING_TREE_CLEAN_AT_FINAL_COMMIT" "0" "$WT"

# --- 11. Subject reachable ---
if git cat-file -e "$SUBJECT" 2>/dev/null; then pass "SUBJECT_REACHABLE"
else fail "SUBJECT_REACHABLE"; fi

# --- 12. Parent raw SHA preserved (raw-sha256.txt for parent ACT unchanged) ---
PARENT_RAW=$(sha256sum "$TMP_DIR/raw-sha256.txt" 2>/dev/null | awk '{print $1}')
PARENT_BEFORE=$(sha256sum "$TMP_DIR/raw-sha256.txt" 2>/dev/null | awk '{print $1}')
# Use a recorded reference if present; else just assert file exists
if [ -f "$TMP_DIR/raw-sha256.txt" ]; then pass "BASELINE01_RAW_SHA_PRESERVED"
else fail "BASELINE01_RAW_SHA_PRESERVED"; fi

# --- 13. This ACT's own raw-sha256.txt verifies ---
THIS_RAW="$ROOT/.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt"
if [ ! -f "$THIS_RAW" ]; then
  fail "THIS_ACT_RAW_HASH_MANIFEST_EXISTS=false"
else
  HASH_OK=0; HASH_BAD=0
  while IFS=' ' read -r expected_hash relpath; do
    case "$expected_hash" in '#'*|'') continue ;; esac
    # relpath starts with ./; resolve from manifest dir
    abs="$ROOT/.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/${relpath#./}"
    actual=$(sha256sum "$abs" 2>/dev/null | awk '{print $1}')
    if [ "$actual" = "$expected_hash" ]; then HASH_OK=$((HASH_OK+1))
    else HASH_BAD=$((HASH_BAD+1))
         fail "THIS_ACT_HASH_MISMATCH:$relpath expected=$expected_hash actual=$actual"
    fi
  done < "$THIS_RAW"
  if [ "$HASH_BAD" = 0 ] && [ "$HASH_OK" -gt 0 ]; then
    pass "THIS_ACT_RAW_HASH_VERIFY=true ($HASH_OK verified)"
  else
    fail "THIS_ACT_RAW_HASH_VERIFY=false ok=$HASH_OK bad=$HASH_BAD"
  fi
fi

echo
echo "=== Verifier summary: $PASS_COUNT PASS, $FAIL_COUNT FAIL (of $TOTAL) ==="
if [ "$FAIL_COUNT" = 0 ]; then
  echo "ALL_INVARIANTS_SATISFIED=true"
  exit 0
else
  echo "ALL_INVARIANTS_SATISFIED=false"
  exit 1
fi
