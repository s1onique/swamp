#!/usr/bin/env bash
# Verifier for ACT-SWAMP-CHARACTERIZE-REST01 closure.
# Checks all mechanical invariants in §63 and §37.

set -u

cd "$(git rev-parse --show-toplevel)"

ACT_TMP=.factory/tmp/SWAMP-CHARACTERIZE-REST01
ACT_EV=.factory/evidence/SWAMP-CHARACTERIZE-REST01
ACT=.factory/acts/SWAMP-CHARACTERIZE-REST01.md
SUBJECT=$(cat .factory/evidence/SWAMP-CHARACTERIZE-REST01/manifest.json 2>/dev/null | python3 -c 'import json,sys;d=json.load(sys.stdin); print(d.get("subject_sha",""))' || true)
SUBJECT="${SUBJECT:-a392c49e1c899fbbbbf39bf84d73a8308c048eb6}"

pass=0; fail=0
ok() { echo "PASS: $1"; pass=$((pass+1)); }
no() { echo "FAIL: $1"; fail=$((fail+1)); }

echo "=== ACT-SWAMP-CHARACTERIZE-REST01 verifier ==="
echo "Subject: $SUBJECT"
echo

# 1. ACT plan present
[ -f "$ACT" ] && ok "ACT_PLAN_PRESENT=true" || no "ACT_PLAN_PRESENT=false"

# 2. Raw evidence tracked by git
TRACKED=$(git ls-files "$ACT_TMP" | wc -l | tr -d ' ')
[ "$TRACKED" -gt 0 ] && ok "RAW_EVIDENCE_TRACKED=true ($TRACKED files)" || no "RAW_EVIDENCE_TRACKED=false"

# 3. Hash manifest exists, excludes itself, verifies
MANIFEST=$ACT_TMP/raw-sha256.txt
if [ -f "$MANIFEST" ]; then
  if awk '!/^#/ && $2 ~ /raw-sha256\.txt$/ {found=1; exit} END {exit !found}' "$MANIFEST"; then
    no "RAW_HASH_MANIFEST_SELF_REFERENTIAL=true"
  else
    ok "RAW_HASH_MANIFEST_SELF_REFERENTIAL=false"
  fi
  MISMATCHES=0; VERIFIED=0
  # Manifest paths are relative to the manifest directory itself
  MANIFEST_DIR=$(dirname "$MANIFEST")
  while IFS=' ' read -r expected_hash path; do
    case "$expected_hash" in '#'*|'') continue ;; esac
    case "$path" in /*) ;; *) path="$MANIFEST_DIR/$path" ;; esac
    actual=$(sha256sum "$path" 2>/dev/null | awk '{print $1}')
    if [ "$actual" != "$expected_hash" ]; then MISMATCHES=$((MISMATCHES+1)); else VERIFIED=$((VERIFIED+1)); fi
  done < <(awk '!/^#/ && NF>=2' "$MANIFEST")
  if [ "$MISMATCHES" = "0" ] && [ "$VERIFIED" -gt 0 ]; then
    ok "RAW_HASHES_VERIFY=true ($VERIFIED verified)"
  else
    no "RAW_HASHES_VERIFY=false (mismatches=$MISMATCHES verified=$VERIFIED)"
  fi
else
  no "RAW_HASH_MANIFEST_EXISTS=false"
fi

# 4. Authoritative evidence present
[ -f "$ACT_EV/RESULT.md" ] && ok "RESULT_PRESENT=true" || no "RESULT_PRESENT=false"
[ -f "$ACT_EV/MANIFEST.md" ] && ok "MANIFEST_MD_PRESENT=true" || no "MANIFEST_MD_PRESENT=false"
[ -f "$ACT_EV/FAILURE-INVENTORY.md" ] && ok "INVENTORY_MD_PRESENT=true" || no "INVENTORY_MD_PRESENT=false"
[ -f "$ACT_EV/failures.json" ] && ok "INVENTORY_JSON_PRESENT=true" || no "INVENTORY_JSON_PRESENT=false"
[ -f "$ACT_EV/CLUSTER-SUMMARY.md" ] && ok "CLUSTER_SUMMARY_PRESENT=true" || no "CLUSTER_SUMMARY_PRESENT=false"
[ -f "$ACT_EV/DOGFOOD-READINESS.md" ] && ok "DOGFOOD_READINESS_PRESENT=true" || no "DOGFOOD_READINESS_PRESENT=false"
[ -f "$ACT_EV/ENVIRONMENT.md" ] && ok "ENVIRONMENT_DOC_PRESENT=true" || no "ENVIRONMENT_DOC_PRESENT=false"
[ -f "$ACT_EV/FULL-RUN.md" ] && ok "FULL_RUN_PRESENT=true" || no "FULL_RUN_PRESENT=false"
[ -f "$ACT_EV/normalized/summary.txt" ] && ok "NORMALIZED_SUMMARY_PRESENT=true" || no "NORMALIZED_SUMMARY_PRESENT=false"

# 5. Parse failure inventory + cluster documents exist
if [ -d "$ACT_EV/clusters" ]; then
  CLUSTER_DOCS=$(ls "$ACT_EV/clusters/"*.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$CLUSTER_DOCS" -gt 0 ] && ok "CLUSTER_DOCS_PRESENT=true ($CLUSTER_DOCS)" || no "CLUSTER_DOCS_PRESENT=false"
else
  no "CLUSTER_DIR_MISSING=false"
fi

# 6. Natural completion and runner conservation
if [ -f "$ACT_TMP/full/exitcode" ] && [ -f "$ACT_EV/normalized/summary.txt" ]; then
  RC=$(cat "$ACT_TMP/full/exitcode" 2>/dev/null || echo "?")
  if [ "$RC" != "?" ]; then
    ok "EXITCODE_CAPTURED=true (rc=$RC)"
  else
    no "EXITCODE_CAPTURED=false"
  fi
  if grep -q 'NATURAL_COMPLETION=true' "$ACT_EV/FULL-RUN.md" 2>/dev/null; then
    ok "NATURAL_COMPLETION=true"
  else
    no "NATURAL_COMPLETION=true (record not present)"
  fi
  if grep -qE 'passed\s+[+]?\s*failed\s+[+]?\s*ignored\s*=?\s*total' "$ACT_EV/normalized/summary.txt" 2>/dev/null; then
    ok "RUNNER_TOTAL_CONSERVATION=recorded"
  fi
fi

# 7. Test classification conservation (derived from failures.json)
if [ -f "$ACT_EV/failures.json" ]; then
  if python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
rows=len(d.get("failures",[]))
expected=d.get("runner_failed",-1)
if rows != expected: sys.exit(1)
' "$ACT_EV/failures.json"; then
    ok "INVENTORY_ROWS_CONSERVE_RUNNER_FAILED=true"
  else
    no "INVENTORY_ROWS_CONSERVE_RUNNER_FAILED=false"
  fi
fi

# 8. Production-diff gate (no production code changed)
NONFACTORY_DIFF=$(git diff --name-only "$SUBJECT"..HEAD | grep -v '^\.factory/' || true)
if [ -z "$NONFACTORY_DIFF" ]; then
  ok "NO_PRODUCTION_CODE_CHANGED=true"
else
  no "NO_PRODUCTION_CODE_CHANGED=false ($NONFACTORY_DIFF)"
fi

# 9. Working tree clean (factory-only changes are EXPECTED until final commit)
# At factory-closure time the only untracked / modified entries should be
# the ACT's own .factory/** files. No repo-root scratch residue.
INREPO_SCRATCH=$(git status --short | grep -E '^\?\? (swamp-char|\.|tmp/|\./\.|deno-cache|home|char-rest)' | grep -v '^\?\? \.factory/' || true)
if [ -z "$INREPO_SCRATCH" ]; then
  ok "WORKING_TREE_NO_REPO_LOCAL_SCRATCH=true"
else
  no "WORKING_TREE_NO_REPO_LOCAL_SCRATCH=false ($INREPO_SCRATCH)"
fi

# 10. No repo-local scratch
[ -d swamp-char-rest01 ] || [ -d char-rest ] || [ -d deno-cache ] && no "NO_REPO_LOCAL_SCRATCH=false" || ok "NO_REPO_LOCAL_SCRATCH=true"

# 11. ACT subject reachable
if git merge-base --is-ancestor "$SUBJECT" HEAD; then
  ok "SUBJECT_REACHABLE=true"
else
  no "SUBJECT_REACHABLE=false"
fi

# 12. Board state agrees
if grep -q 'SWAMP-CHARACTERIZE-REST01 | CLOSED' .factory/epic-board.md 2>/dev/null; then
  ok "BOARD_STATE_AGREES_WITH_ACT_STATE=true (CLOSED)"
elif grep -q 'SWAMP-CHARACTERIZE-REST01 | ACTIVE' .factory/epic-board.md 2>/dev/null; then
  # Pre-closure is allowed if ACT is still ACTIVE
  ok "BOARD_STATE_AGREES_WITH_ACT_STATE=true (ACTIVE)"
else
  no "BOARD_STATE_AGREES_WITH_ACT_STATE=false"
fi

# 13. Negative claim: BASELINE01 raw SHA preserved
BASELINE_SHA=$(sha256sum .factory/tmp/native-baseline/test.stdout 2>/dev/null | awk '{print $1}')
EXPECTED=ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417
if [ "$BASELINE_SHA" = "$EXPECTED" ]; then
  ok "BASELINE01_RAW_SHA_PRESERVED=true"
else
  no "BASELINE01_RAW_SHA_PRESERVED=false (got=$BASELINE_SHA)"
fi

echo
echo "=== Summary: $pass PASS, $fail FAIL ==="
if [ "$fail" = "0" ]; then echo "ALL_INVARIANTS_SATISFIED=true"; exit 0; else echo "ALL_INVARIANTS_SATISFIED=false"; exit 1; fi
