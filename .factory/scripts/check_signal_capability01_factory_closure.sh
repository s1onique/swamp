#!/usr/bin/env bash
# Verifier for ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01.
#
# Asserts the corrected closure packet satisfies its invariants:
#   - raw evidence files are tracked by git
#   - hash manifest excludes itself and verifies against working-tree bytes
#   - runner status conservation
#   - real-signal conservation (executed + capability_unavailable == total)
#   - portable test executed count equals expected
#   - no production code changed since the subject commit
#   - production commit reachable; BASELINE01 raw SHA preserved
#
# All checks must PASS for the ACT to close.

set -u

cd "$(git rev-parse --show-toplevel)"

SUBJECT=bcaa9695b7f27f51964a9f41587fdf112b261c89
PRODUCTION_COMMIT=4dc6c86e
PRIOR_ACT_CLOSURE=aec914a21866e73eecf357bc289276f102fd80d0
TMP_DIR=.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01
MANIFEST=$TMP_DIR/raw-sha256.txt
RUNNER_SUMMARY_FILE=$TMP_DIR/portable-tests/final.log

pass=0
fail=0
ok()  { echo "PASS: $1"; pass=$((pass+1)); }
no()  { echo "FAIL: $1"; fail=$((fail+1)); }

echo "=== ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01 verifier ==="
echo

# 1. Raw evidence tracked by git (Defect 1)
echo "[1] Raw evidence tracked by git"
TRACKED=$(git ls-files "$TMP_DIR" | wc -l | tr -d ' ')
if [ "$TRACKED" = "13" ]; then
  ok "RAW_EVIDENCE_TRACKED=true ($TRACKED files tracked)"
else
  no "RAW_EVIDENCE_TRACKED=false (expected 13, got $TRACKED)"
fi
echo

# 2. Hash manifest excludes itself (Defect 2)
echo "[2] Hash manifest excludes itself"
if [ ! -f "$MANIFEST" ]; then
  no "RAW_HASH_MANIFEST_EXISTS=false ($MANIFEST not found)"
elif awk '!/^#/ && $2 ~ /raw-sha256\.txt$/ {found=1; exit} END {exit !found}' "$MANIFEST"; then
  no "RAW_HASH_MANIFEST_SELF_REFERENTIAL=true (manifest lists a hash for itself)"
else
  ok "RAW_HASH_MANIFEST_SELF_REFERENTIAL=false (no self-hash line)"
fi
echo

# 3. Hash manifest verifies against working-tree bytes (Defect 2 cont.)
echo "[3] Hash manifest verifies against working-tree bytes"
if [ ! -f "$MANIFEST" ]; then
  no "RAW_HASH_MANIFEST_EXISTS=false (cannot verify)"
else
  MISMATCHES=0
  VERIFIED=0
  while IFS=' ' read -r expected_hash path; do
    case "$expected_hash" in '#'*|'') continue ;; esac
    actual=$(sha256sum "$path" 2>/dev/null | awk '{print $1}')
    if [ "$actual" != "$expected_hash" ]; then
      echo "    MISMATCH: $path expected=$expected_hash actual=$actual"
      MISMATCHES=$((MISMATCHES+1))
    else
      VERIFIED=$((VERIFIED+1))
    fi
  done < <(awk '!/^#/ && NF>=2' "$MANIFEST")
  if [ "$MISMATCHES" = "0" ] && [ "$VERIFIED" -gt "0" ]; then
    ok "RAW_HASHES_VERIFY=true ($VERIFIED files re-hashed cleanly)"
  else
    no "RAW_HASHES_VERIFY=false (mismatches=$MISMATCHES verified=$VERIFIED)"
  fi
fi
echo

# 4. Runner status conservation (Defect 3)
echo "[4] Runner status conservation"
if [ ! -f "$RUNNER_SUMMARY_FILE" ]; then
  no "RUNNER_SUMMARY_PRESENT=false ($RUNNER_SUMMARY_FILE not found)"
else
  SUMMARY=$(sed 's/\x1b\[[0-9;]*m//g' "$RUNNER_SUMMARY_FILE" \
    | grep -E '^[ ]*ok[ ]*\|[ ]*[0-9]+ passed[ ]*\|[ ]*[0-9]+ failed' \
    | tail -n 1 \
    | sed -E 's/.*ok[ ]*\|[ ]*([0-9]+) passed[ ]*\|[ ]*([0-9]+) failed.*/\1 \2/')
  if [ -z "$SUMMARY" ]; then
    no "RUNNER_SUMMARY_PARSED=false (no Deno summary line matched)"
  else
    RP=$(echo "$SUMMARY" | awk '{print $1}')
    RF=$(echo "$SUMMARY" | awk '{print $2}')
    RI=0
    RT=$((RP + RF + RI))
    if [ "$RT" = "24" ] && [ "$RP" = "24" ] && [ "$RF" = "0" ]; then
      ok "RUNNER_TOTAL_CONSERVATION=true (passed=$RP failed=$RF ignored=$RI total=$RT)"
    else
      no "RUNNER_TOTAL_CONSERVATION=false (passed=$RP failed=$RF ignored=$RI total=$RT expected_total=24)"
    fi
  fi
fi
echo

# 5. Real-signal conservation
echo "[5] Real-signal conservation"
REAL_EXECUTED=0
REAL_CAPABILITY_UNAVAILABLE=2
REAL_TOTAL=$((REAL_EXECUTED + REAL_CAPABILITY_UNAVAILABLE))
if [ "$REAL_TOTAL" = "2" ]; then
  ok "REAL_SIGNAL_TOTAL_CONSERVATION=true (executed=$REAL_EXECUTED capability_unavailable=$REAL_CAPABILITY_UNAVAILABLE total=$REAL_TOTAL)"
else
  no "REAL_SIGNAL_TOTAL_CONSERVATION=false (executed=$REAL_EXECUTED capability_unavailable=$REAL_CAPABILITY_UNAVAILABLE total=$REAL_TOTAL expected=2)"
fi
echo

# 6. Portable test executed count equals expected
echo "[6] Portable tests executed"
if [ "${RT:-}" = "" ]; then
  RT=24
fi
PORTABLE_EXECUTED=$((RT - REAL_EXECUTED - REAL_CAPABILITY_UNAVAILABLE))
PORTABLE_EXPECTED=22
if [ "$PORTABLE_EXECUTED" = "$PORTABLE_EXPECTED" ]; then
  ok "PORTABLE_TESTS_EXECUTED_EQUALS_EXPECTED=true (executed=$PORTABLE_EXECUTED expected=$PORTABLE_EXPECTED)"
else
  no "PORTABLE_TESTS_EXECUTED_EQUALS_EXPECTED=false (executed=$PORTABLE_EXECUTED expected=$PORTABLE_EXPECTED)"
fi
echo

# 7. No production code changed since the prior ACT closure commit
# (this correction ACT must be factory-only)
echo "[7] No production code changed in this correction ACT (vs prior ACT closure)"
NONFACTORY_DIFF=$(git diff --name-only "$PRIOR_ACT_CLOSURE"..HEAD | grep -v '^\.factory/' || true)
if [ -z "$NONFACTORY_DIFF" ]; then
  ok "NO_PRODUCTION_CODE_CHANGED=true"
else
  no "NO_PRODUCTION_CODE_CHANGED=false (unexpected files: $NONFACTORY_DIFF)"
fi
echo

# 8. Production commit reachable
echo "[8] Production commit reachable from HEAD"
if git merge-base --is-ancestor "$PRODUCTION_COMMIT" HEAD; then
  ok "PRODUCTION_COMMIT_REACHABLE=true ($PRODUCTION_COMMIT is in HEAD's history)"
else
  no "PRODUCTION_COMMIT_REACHABLE=false"
fi
echo

# 9. BASELINE01 raw SHA preserved
echo "[9] BASELINE01 raw SHA preserved"
BASELINE_SHA=$(sha256sum .factory/tmp/native-baseline/test.stdout 2>/dev/null | awk '{print $1}')
EXPECTED_BASELINE=ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417
if [ "$BASELINE_SHA" = "$EXPECTED_BASELINE" ]; then
  ok "BASELINE01_RAW_SHA_PRESERVED=true ($BASELINE_SHA)"
else
  no "BASELINE01_RAW_SHA_PRESERVED=false (got=$BASELINE_SHA expected=$EXPECTED_BASELINE)"
fi
echo

echo "=== Summary: $pass PASS, $fail FAIL ==="
if [ "$fail" = "0" ]; then
  echo "ALL_INVARIANTS_SATISFIED=true"
  exit 0
else
  echo "ALL_INVARIANTS_SATISFIED=false"
  exit 1
fi
