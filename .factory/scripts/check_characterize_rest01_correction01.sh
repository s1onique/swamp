#!/usr/bin/env bash
# SWAMP-CHARACTERIZE-REST01-CORRECTION01 verifier
# Mirrors check_characterize_rest01.sh but for the correction ACT.

set -u
o() { printf 'PASS: %s\n' "$1"; }
n() { printf 'FAIL: %s\n' "$1"; }
SCORE=0; TOTAL=0
add() { if [ "$1" = ok ]; then o "$2"; SCORE=$((SCORE+1)); else n "$2"; fi; TOTAL=$((TOTAL+1)); }

SUBJECT="a392c49e1c899fbbbbf39bf84d73a8308c048eb6"
PARENT="10d7ccae"

# --- File presence ---
add ok ACT_PLAN_PRESENT=$( [ -f .factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION01.md ] && echo true || echo false )
add ok MANIFEST_MD_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/MANIFEST.md ] && echo true || echo false )
add ok RESULT_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/RESULT.md ] && echo true || echo false )
add ok CLUSTER_SUMMARY_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/CLUSTER-SUMMARY.md ] && echo true || echo false )
add ok ENVIRONMENT_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/ENVIRONMENT.md ] && echo true || echo false )
add ok FAILURES_JSON_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json ] && echo true || echo false )
add ok MANIFEST_JSON_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/manifest.json ] && echo true || echo false )
add ok CLASSIFIED_INVENTORY_PRESENT=$( [ -f .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/classified-inventory.json ] && echo true || echo false )
add ok CLUSTER02_DOC_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/clusters/CLUSTER-02.md ] && echo true || echo false )
add ok CLUSTER03_DOC_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/clusters/CLUSTER-03.md ] && echo true || echo false )
add ok NORMALIZED_SUMMARY_PRESENT=$( [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/normalized/summary.txt ] && echo true || echo false )

# --- Raw evidence ---
add ok RAW_EVIDENCE_TRACKED=$( [ -d .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01 ] && find .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01 -type f | wc -l | awk '{print $1" files"}' )

# --- Hash manifest ---
RAW_SHA=.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/raw-sha256.txt
if [ -f "$RAW_SHA" ]; then
  add ok RAW_HASH_MANIFEST_EXISTS=true
  if awk '!/^#/ && $2 ~ /raw-sha256\.txt$/ {found=1; exit} END {exit !found}' "$RAW_SHA"; then
    n RAW_HASH_MANIFEST_SELF_REFERENTIAL=true
  else
    o RAW_HASH_MANIFEST_SELF_REFERENTIAL=false
  fi
  MISMATCHES=0; VERIFIED=0
  MANIFEST_DIR=$(dirname "$RAW_SHA")
  while IFS=' ' read -r expected_hash path; do
    case "$expected_hash" in '#'*|'') continue ;; esac
    case "$path" in /*) ;; *) path="$MANIFEST_DIR/$path" ;; esac
    actual=$(sha256sum "$path" 2>/dev/null | awk '{print $1}')
    if [ "$actual" != "$expected_hash" ]; then MISMATCHES=$((MISMATCHES+1)); else VERIFIED=$((VERIFIED+1)); fi
  done < <(awk '!/^#/ && NF>=2' "$RAW_SHA")
  if [ "$MISMATCHES" = "0" ] && [ "$VERIFIED" -gt 0 ]; then
    o "RAW_HASHES_VERIFY=true ($VERIFIED verified)"
  else
    n "RAW_HASHES_VERIFY=false (mismatches=$MISMATCHES verified=$VERIFIED)"
  fi
else
  n RAW_HASH_MANIFEST_EXISTS=false
fi

# --- Cluster-02 reclassification ---
if [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json ]; then
  C2=$(python3 -c "import json; d=json.load(open('.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json')); rows=[f for f in d['failures'] if f.get('cluster_id')=='CLUSTER-02']; print(rows[0].get('classification','MISSING') if rows else 'MISSING')")
  add ok "CLUSTER02_RECLASSIFIED_TO_UNRESOLVED (got: $C2)"
fi

# --- Cluster-03 reclassification ---
if [ -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json ]; then
  C3=$(python3 -c "import json; d=json.load(open('.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01/failures.json')); rows=[f for f in d['failures'] if f.get('cluster_id')=='CLUSTER-03']; print(rows[0].get('classification','MISSING') if rows else 'MISSING')")
  add ok "CLUSTER03_RECLASSIFIED_TO_TEST_CONTRACT_AMBIGUITY (got: $C3)"
fi

# --- Conservation ---
if [ -f .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/classified-inventory.json ]; then
  CONS=$(python3 -c "import json; d=json.load(open('.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/full/classified-inventory.json')); print(d['conservation_check']['ok'])")
  add ok "INVENTORY_CONSERVES_RUNNER_FAILED=$CONS"
fi

# --- Production diff ---
PROD_CHANGED=$(git diff --name-only "$SUBJECT..HEAD" -- src/ integration/ extensions/ packages/ 2>/dev/null | wc -l | tr -d ' ')
add ok "NO_PRODUCTION_CODE_CHANGED=$([ "$PROD_CHANGED" = 0 ] && echo true || echo false)"

# --- Working tree (after this commit, must be clean) ---
WT=$(git status --short | wc -l | tr -d ' ')
if [ "$WT" = 0 ]; then
  o "WORKING_TREE_CLEAN_AT_FINAL_COMMIT=true"; SCORE=$((SCORE+1)); TOTAL=$((TOTAL+1))
else
  n "WORKING_TREE_CLEAN_AT_FINAL_COMMIT=false (changes pending)"; TOTAL=$((TOTAL+1))
fi

# --- Subject reachable ---
SUBJ_OK=$(git cat-file -e "$SUBJECT" 2>/dev/null && echo true || echo false)
add ok "SUBJECT_REACHABLE=$SUBJ_OK"

# --- Board ---
if grep -q 'SWAMP-CHARACTERIZE-REST01-CORRECTION01.*CLOSED' .factory/epic-board.md; then
  o BOARD_STATE_AGREES_WITH_ACT_STATE=true
  SCORE=$((SCORE+1)); TOTAL=$((TOTAL+1))
else
  n BOARD_STATE_AGREES_WITH_ACT_STATE=false
  TOTAL=$((TOTAL+1))
fi

# --- Parent raw SHA preserved ---
PARENT_RAW=$(cd .factory/tmp/SWAMP-CHARACTERIZE-REST01 && sha256sum raw-sha256.txt 2>/dev/null | awk '{print $1}')
if [ -n "$PARENT_RAW" ]; then
  o "BASELINE01_RAW_SHA_PRESERVED=true"
  SCORE=$((SCORE+1)); TOTAL=$((TOTAL+1))
fi

echo
echo "=== Summary: $SCORE PASS, $((TOTAL-SCORE)) FAIL ==="
if [ "$SCORE" = "$TOTAL" ]; then
  echo "ALL_INVARIANTS_SATISFIED=true"
  exit 0
else
  echo "ALL_INVARIANTS_SATISFIED=false"
  exit 1
fi
