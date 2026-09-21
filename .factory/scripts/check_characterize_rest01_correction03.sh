#!/usr/bin/env bash
# SWAMP-CHARACTERIZE-REST01-CORRECTION03 verifier
#
# Verifies content predicates (pre-commit) and post-commit
# predicates (post-commit) of the corrected characterization
# closure. Every authority-bearing check has a falsifiable
# predicate and a corresponding PASS/FAIL increment.
#
# Required invocation:
#   .factory/scripts/check_characterize_rest01_correction03.sh --mode <precommit|postcommit>
#
# Defaults to --mode precommit if the mode flag is omitted.

set -u

MODE="${MODE:-precommit}"
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --mode=*) MODE="${1#*=}"; shift ;;
    --help|-h)
      cat <<'EOF'
Usage: check_characterize_rest01_correction03.sh --mode <precommit|postcommit>

  precommit   verify content and authority-bearing projections
              (does not require a clean working tree)
  postcommit  verify precommit predicates plus post-commit
              predicates:
                HEAD equals the bound content commit
                working tree clean
                subject reachable
                commit scope factory-only
                evidence resolves from content commit
                parent hash still matches historical blob

This verifier emits, on stdout, deterministic machine lines:

  VERIFIER_TOTAL=<N>
  VERIFIER_PASS=<N>
  VERIFIER_FAIL=<N>
  VERIFIER_RESULT=<PASS|FAIL>
  PARENT_CHARACTERIZATION_RAW_MANIFEST_EXPECTED_SHA256=<sha>
  PARENT_CHARACTERIZATION_RAW_MANIFEST_ACTUAL_SHA256=<sha>
  PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED=<true|false>
  CONTENT_COMMIT_SHA=<sha>           (postcommit only)
  CONTENT_TREE_SHA=<sha>             (postcommit only)
  WORKING_TREE_CLEAN_AT_MEASUREMENT=<true|false>  (postcommit only)

Exit codes:
  0   all invariants satisfied
  1   at least one invariant failed
EOF
      exit 0
      ;;
    *) shift ;;
  esac
done

case "$MODE" in
  precommit|postcommit) ;;
  *) echo "FAIL: bad mode: $MODE" >&2; exit 2 ;;
esac

# Resolve repo root: script is at .factory/scripts/<name>; cd two levels up.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SUBJECT="a392c49e1c899fbbbbf39bf84d73a8308c048eb6"
PARENT_COMMIT="19d6d2e093e1bbc9e2cb160a19018444874444aa"
PARENT_RAW_MANIFEST_PATH=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION02/raw-sha256.txt"

EVID_DIR=.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION01
C03_EVID=.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03
TMP_DIR=.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01
INV="$TMP_DIR/full/classified-inventory.json"
FAIL="$EVID_DIR/failures.json"
MAN="$EVID_DIR/MANIFEST.md"
RES="$EVID_DIR/RESULT.md"
NORM="$EVID_DIR/normalized/summary.txt"
CLSUM="$EVID_DIR/CLUSTER-SUMMARY.md"
CL02="$EVID_DIR/clusters/CLUSTER-02.md"
CL03="$EVID_DIR/clusters/CLUSTER-03.md"
EPIC=".factory/epic-board.md"
C03_MANIFEST="$C03_EVID/manifest.json"
C03_NORM="$C03_EVID/normalized/summary.txt"

# Load canonical machine projection (single source of truth).
read_manifest_field() {
  python3 -c "import json,sys; print(json.load(open('$C03_MANIFEST'))$1)" 2>/dev/null
}
CANON_C1_CLASS=$(read_manifest_field "['canonical_classifications']['CLUSTER-01']['classification']")
CANON_C1_OWNER=$(read_manifest_field "['canonical_classifications']['CLUSTER-01']['cause_owner']")
CANON_C1_EVID=$(read_manifest_field "['canonical_classifications']['CLUSTER-01']['evidence_strength']")
CANON_C1_COUNT=$(read_manifest_field "['canonical_classifications']['CLUSTER-01']['count']")
CANON_C2_CLASS=$(read_manifest_field "['canonical_classifications']['CLUSTER-02']['classification']")
CANON_C2_OWNER=$(read_manifest_field "['canonical_classifications']['CLUSTER-02']['cause_owner']")
CANON_C2_EVID=$(read_manifest_field "['canonical_classifications']['CLUSTER-02']['evidence_strength']")
CANON_C2_COUNT=$(read_manifest_field "['canonical_classifications']['CLUSTER-02']['count']")
CANON_C3_CLASS=$(read_manifest_field "['canonical_classifications']['CLUSTER-03']['classification']")
CANON_C3_OWNER=$(read_manifest_field "['canonical_classifications']['CLUSTER-03']['cause_owner']")
CANON_C3_EVID=$(read_manifest_field "['canonical_classifications']['CLUSTER-03']['evidence_strength']")
CANON_C3_COUNT=$(read_manifest_field "['canonical_classifications']['CLUSTER-03']['count']")
CANON_TOTAL=$(read_manifest_field "['aggregate']['total']")
CANON_ENV_COUNT=$(read_manifest_field "['aggregate']['ENVIRONMENTAL']")
CANON_UNR_COUNT=$(read_manifest_field "['aggregate']['UNRESOLVED']")
CANON_TCA_COUNT=$(read_manifest_field "['aggregate']['TEST_CONTRACT_AMBIGUITY']")
CANON_NUK=$(read_manifest_field "['aggregate']['no_unknown_red']" | tr '[:upper:]' '[:lower:]')
CANON_DOG=$(read_manifest_field "['aggregate']['DOGFOOD_READY']" | tr '[:upper:]' '[:lower:]')
CANON_PROJ_COUNT=$(read_manifest_field "['projection_count']")
CANON_PROJ_JSON=$(read_manifest_field "['authoritative_projections']")

# --- observation / predicate / assertion helpers ---
o()   { printf 'PASS: %s\n' "$1"; }
n()   { printf 'FAIL: %s\n' "$1"; }
PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0
pass() { o "$1"; PASS_COUNT=$((PASS_COUNT+1)); TOTAL=$((TOTAL+1)); }
fail() { n "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); TOTAL=$((TOTAL+1)); }
check() {
  # check "name" "expected" "observed"  -> dispatches to pass/fail by equality
  if [ "$2" = "$3" ]; then
    pass "$1 (=$3)"
  else
    fail "$1 expected=$2 observed=$3"
  fi
}
check_py() {
  # check_py "name" "expected" "python_expr"   python_expr has access to $FAIL etc.
  local name="$1" expected="$2" expr="$3"
  local observed
  observed=$(python3 -c "$expr" 2>/dev/null || echo PYERROR)
  check "$name" "$expected" "$observed"
}

# ============================================================
# CONTENT (PRECOMMIT) PREDICATES
# ============================================================

echo "== mode=$MODE =="

# --- 1. Required files exist ---
for f in "$FAIL" "$INV" "$RES" "$CLSUM" "$MAN" "$NORM" "$CL02" "$CL03" \
         "$C03_MANIFEST" "$C03_NORM" "$EPIC"; do
  if [ -f "$f" ]; then pass "FILE_PRESENT: $(basename "$f")"
  else fail "FILE_MISSING: $f"; fi
done

# --- 2. Canonical classifications agree with machine projection ---
# failures.json per-cluster
F_C1=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-01']; print(rows[0]['classification'] if rows else 'MISSING')")
F_C2=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-02']; print(rows[0]['classification'] if rows else 'MISSING')")
F_C3=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-03']; print(rows[0]['classification'] if rows else 'MISSING')")
check "failures.json:CLUSTER-01.classification" "$CANON_C1_CLASS" "$F_C1"
check "failures.json:CLUSTER-02.classification" "$CANON_C2_CLASS" "$F_C2"
check "failures.json:CLUSTER-03.classification" "$CANON_C3_CLASS" "$F_C3"

F_C1_OWNER=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-01']; print(rows[0]['cause_owner'] if rows else 'MISSING')")
F_C2_OWNER=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-02']; print(rows[0]['cause_owner'] if rows else 'MISSING')")
F_C3_OWNER=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-03']; print(rows[0]['cause_owner'] if rows else 'MISSING')")
check "failures.json:CLUSTER-01.cause_owner" "$CANON_C1_OWNER" "$F_C1_OWNER"
check "failures.json:CLUSTER-02.cause_owner" "$CANON_C2_OWNER" "$F_C2_OWNER"
check "failures.json:CLUSTER-03.cause_owner" "$CANON_C3_OWNER" "$F_C3_OWNER"

F_C1_EV=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-01']; print(rows[0]['evidence_strength'] if rows else 'MISSING')")
F_C2_EV=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-02']; print(rows[0]['evidence_strength'] if rows else 'MISSING')")
F_C3_EV=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='CLUSTER-03']; print(rows[0]['evidence_strength'] if rows else 'MISSING')")
check "failures.json:CLUSTER-01.evidence_strength" "$CANON_C1_EVID" "$F_C1_EV"
check "failures.json:CLUSTER-02.evidence_strength" "$CANON_C2_EVID" "$F_C2_EV"
check "failures.json:CLUSTER-03.evidence_strength" "$CANON_C3_EVID" "$F_C3_EV"

# --- 3. failures.json conservation ---
F_CONS=$(python3 -c "import json; d=json.load(open('$FAIL')); print(json.dumps(d.get('classification_conservation',{}),sort_keys=True))")
EXP_CONS=$(printf '{"ENVIRONMENTAL": %s, "TEST_CONTRACT_AMBIGUITY": %s, "UNRESOLVED": %s}' \
  "$CANON_ENV_COUNT" "$CANON_TCA_COUNT" "$CANON_UNR_COUNT")
check "failures.json:classification_conservation" "$EXP_CONS" "$F_CONS"

F_NUK=$(python3 -c "import json; d=json.load(open('$FAIL')); print(str(d.get('no_unknown_red')).lower())")
check "failures.json:no_unknown_red" "$CANON_NUK" "$F_NUK"

# Total failures in failures.json rows must equal CANON_TOTAL
F_TOTAL=$(python3 -c "import json; d=json.load(open('$FAIL')); print(sum(1 for r in d.get('failures',[]) if r.get('cluster_id') in ('CLUSTER-01','CLUSTER-02','CLUSTER-03')))")
check "failures.json:clustered_failure_count" "$CANON_TOTAL" "$F_TOTAL"

# --- 4. classified-inventory.json ---
for cid in CLUSTER-01 CLUSTER-02 CLUSTER-03; do
  IC_CLASS=$(python3 -c "import json; d=json.load(open('$INV')); print(d.get('clusters',{}).get('$cid',{}).get('classification','MISSING'))")
  IC_OWNER=$(python3 -c "import json; d=json.load(open('$INV')); print(d.get('clusters',{}).get('$cid',{}).get('cause_owner','MISSING'))")
  IC_EV=$(python3 -c "import json; d=json.load(open('$INV')); print(d.get('clusters',{}).get('$cid',{}).get('evidence_strength','MISSING'))")
  case "$cid" in
    CLUSTER-01) check "inventory:$cid.classification" "$CANON_C1_CLASS" "$IC_CLASS"
                check "inventory:$cid.cause_owner"    "$CANON_C1_OWNER" "$IC_OWNER"
                check "inventory:$cid.evidence_strength" "$CANON_C1_EVID" "$IC_EV" ;;
    CLUSTER-02) check "inventory:$cid.classification" "$CANON_C2_CLASS" "$IC_CLASS"
                check "inventory:$cid.cause_owner"    "$CANON_C2_OWNER" "$IC_OWNER"
                check "inventory:$cid.evidence_strength" "$CANON_C2_EVID" "$IC_EV" ;;
    CLUSTER-03) check "inventory:$cid.classification" "$CANON_C3_CLASS" "$IC_CLASS"
                check "inventory:$cid.cause_owner"    "$CANON_C3_OWNER" "$IC_OWNER"
                check "inventory:$cid.evidence_strength" "$CANON_C3_EVID" "$IC_EV" ;;
  esac
done

# --- 5. Cross-projection equality (failures.json vs classified-inventory.json) ---
for cid in CLUSTER-01 CLUSTER-02 CLUSTER-03; do
  FC=$(python3 -c "import json; d=json.load(open('$FAIL')); rows=[r for r in d['failures'] if r['cluster_id']=='$cid']; print(rows[0]['classification'] if rows else 'MISSING')")
  IC=$(python3 -c "import json; d=json.load(open('$INV')); print(d.get('clusters',{}).get('$cid',{}).get('classification','MISSING'))")
  check "CROSS_PROJ:$cid.classification" "$FC" "$IC"
done

# --- 6. Bounded prose projection checks (not naked grep) ---
# CLUSTER-SUMMARY.md table is:
#   | Cluster | Count | Prior primary | Corrected primary | Prior evidence | Corrected evidence |
# The canonical row must show the corrected primary classification and
# corrected evidence_strength, both free of the stale label.
# Strip '**bold**' and ' (unchanged)' annotation; the latter appears on
# CLUSTER-01 because evidence_strength did not change.

check_py "CLUSTER-SUMMARY.md:CLUSTER-01 row bounded" "PASS" "
import re
def _strip(s): return s.replace('**','').replace(' (unchanged)','').strip()
text = open('$CLSUM').read()
m = re.search(r'CLUSTER-01\s*\|[^|]*\|[^|]*\|([^|]+)\|[^|]*\|([^|]+)\|', text)
if not m: print('NO_ROW'); raise SystemExit
cls = _strip(m.group(1))
ev  = _strip(m.group(2))
ok = (cls == '$CANON_C1_CLASS' and ev == '$CANON_C1_EVID')
print('PASS' if ok else f'FAIL:cls={cls!r} ev={ev!r}')"

check_py "CLUSTER-SUMMARY.md:CLUSTER-02 row bounded" "PASS" "
import re
def _strip(s): return s.replace('**','').replace(' (unchanged)','').strip()
text = open('$CLSUM').read()
m = re.search(r'CLUSTER-02\s*\|[^|]*\|[^|]*\|([^|]+)\|[^|]*\|([^|]+)\|', text)
if not m: print('NO_ROW'); raise SystemExit
cls = _strip(m.group(1))
ev  = _strip(m.group(2))
ok = (cls == '$CANON_C2_CLASS' and ev == '$CANON_C2_EVID')
print('PASS' if ok else f'FAIL:cls={cls!r} ev={ev!r}')"

check_py "CLUSTER-SUMMARY.md:CLUSTER-03 row bounded" "PASS" "
import re
def _strip(s): return s.replace('**','').replace(' (unchanged)','').strip()
text = open('$CLSUM').read()
m = re.search(r'CLUSTER-03\s*\|[^|]*\|[^|]*\|([^|]+)\|[^|]*\|([^|]+)\|', text)
if not m: print('NO_ROW'); raise SystemExit
cls = _strip(m.group(1))
ev  = _strip(m.group(2))
ok = (cls == '$CANON_C3_CLASS' and ev == '$CANON_C3_EVID')
print('PASS' if ok else f'FAIL:cls={cls!r} ev={ev!r}')"

# CLUSTER-02.md row context: must contain UNRESOLVED, UNKNOWN, OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
check_py "clusters/CLUSTER-02.md:row context" "PASS" "
text = open('$CL02').read()
need = ('CLUSTER-02','UNRESOLVED','UNKNOWN','OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD')
print('PASS' if all(t in text for t in need) else 'FAIL')"

# CLUSTER-03.md row context: must contain TEST_CONTRACT_AMBIGUITY, REPRODUCED_REPEATEDLY.
# Note: the prose file labels cause_owner as 'SWAMP (test contract)' rather than the
# canonical machine token 'SWAMP_TEST_CONTRACT'. Accept either rendering.
check_py "clusters/CLUSTER-03.md:row context" "PASS" "
text = open('$CL03').read()
need = ('CLUSTER-03','TEST_CONTRACT_AMBIGUITY','REPRODUCED_REPEATEDLY')
ok = all(t in text for t in need)
# additional check: prose must not still claim 'PROJECT_DEFECT' as the classification
ok = ok and ('PROJECT_DEFECT' not in text or 'reclassified from PROJECT_DEFECT' in text)
# additional check: cause_owner must use either 'SWAMP_TEST_CONTRACT' or 'SWAMP (test contract)'
ok = ok and ('SWAMP_TEST_CONTRACT' in text or 'SWAMP (test contract)' in text)
print('PASS' if ok else 'FAIL')"

# normalized/summary.txt conservation block — derive the exact strings
# from the file itself rather than building them by hand. This avoids
# alignment-padding drift when counts change.
check_py "normalized/summary.txt:conservation block" "PASS" "
import re
t = open('$NORM').read()
# match '<LABEL><spaces>= <spaces><N>' with any amount of whitespace.
def has(label, n):
  return re.search(r'^\s*' + re.escape(label) + r'\s*=\s*' + re.escape(str(n)) + r'\b', t, re.M) is not None
ok = (has('ENVIRONMENTAL', $CANON_ENV_COUNT)
      and has('UNRESOLVED', $CANON_UNR_COUNT)
      and has('TEST_CONTRACT_AMBIGUITY', $CANON_TCA_COUNT))
print('PASS' if ok else 'FAIL')"

# RESULT.md verdict line
check_py "RESULT.md:verdict line" "PASS" "
t = open('$RES').read()
print('PASS' if 'REMAINING_FAILURE_SURFACE_MIXED' in t else 'FAIL')"

# --- 7. epic-board has CORRECTION03 row with correct state ---
# In precommit mode, the row must match BOARD_EXPECTED_STATE (default
# CLOSED_PENDING_ATTESTATION). In postcommit mode, this check is
# superseded by the more rigorous BOARD_STATE_AGREES_WITH_ACT_STATE
# check below, which reads the board from HEAD's tree.
if [ "$MODE" = "precommit" ]; then
  EXP_STATE="${BOARD_EXPECTED_STATE:-CLOSED_PENDING_ATTESTATION}"
  check_py "epic-board:CORRECTION03 row state" "PASS" "
import re
t = open('$EPIC').read()
m = re.search(r'SWAMP-CHARACTERIZE-REST01-CORRECTION03\s*\|\s*(\S+)', t)
print('PASS' if (m and m.group(1).strip() == '$EXP_STATE') else 'FAIL')"
else
  : # no-op in postcommit; covered by BOARD_STATE_AGREES_WITH_ACT_STATE
fi

# --- 8. Classification conservation ---
ENV=$CANON_ENV_COUNT
UNR=$CANON_UNR_COUNT
TCA=$CANON_TCA_COUNT
SUM=$((ENV + UNR + TCA))
check "ARITHMETIC:ENV+UNR+TCA==total" "$CANON_TOTAL" "$SUM"

# --- 9. DOGFOOD_READY gating ---
check_py "GATE:DOGFOOD_READY" "$CANON_DOG" "
# canonical: DOGFOOD_READY is false because no_unknown_red==false (UNKNOWN cause_owner exists)
# Always emit lowercase 'true'/'false' to match JSON serialization.
nuk = '$CANON_NUK'.strip().lower()
print('false' if nuk == 'false' else 'true')"

# --- 10. Production code diff at content commit is empty ---
# precommit: compare HEAD against the parent commit. We expect zero
#   production files touched between parent and HEAD (Factory-only).
# postcommit: same check, against the bound content commit.
if [ "$MODE" = "postcommit" ]; then
  PROD_REF="${CONTENT_COMMIT_SHA:-${C03_CONTENT_COMMIT:-$PARENT_COMMIT}}"
else
  PROD_REF="$PARENT_COMMIT"
fi
PROD_CHANGED=$(git diff --name-only "$PROD_REF..HEAD" -- src/ integration/ extensions/ packages/ deno.json deno.lock 2>/dev/null | wc -l | tr -d ' ')
check "NO_PRODUCTION_CODE_CHANGED (ref=$PROD_REF)" "0" "$PROD_CHANGED"

# --- 11. PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED (D1 fix) ---
# Independent historical reference: pull the blob from Git history, hash it,
# then compare with the current committed parent manifest blob hash.
# Use git rev-parse + git cat-file blob to get the exact bytes (no trailing
# newline stripping the way $() substitution or `git show` does).
EXPECTED_PARENT_RAW_MANIFEST_SHA256=""
ACTUAL_PARENT_RAW_MANIFEST_SHA256=""
if ! git cat-file -e "$PARENT_COMMIT" 2>/dev/null; then
  fail "PARENT_COMMIT_REACHABLE"
else
  HIST_BLOB_SHA=$(git rev-parse "$PARENT_COMMIT:$PARENT_RAW_MANIFEST_PATH" 2>/dev/null || true)
  if [ -z "$HIST_BLOB_SHA" ]; then
    fail "PARENT_RAW_MANIFEST_HISTORICAL_BLOB_RETRIEVABLE"
  else
    EXPECTED_PARENT_RAW_MANIFEST_SHA256=$(git cat-file blob "$HIST_BLOB_SHA" | sha256sum | awk '{print $1}')
    ACTUAL_PARENT_RAW_MANIFEST_SHA256=$(sha256sum "$PARENT_RAW_MANIFEST_PATH" | awk '{print $1}')
    if [ "$EXPECTED_PARENT_RAW_MANIFEST_SHA256" = "$ACTUAL_PARENT_RAW_MANIFEST_SHA256" ]; then
      pass "PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED (=$ACTUAL_PARENT_RAW_MANIFEST_SHA256)"
    else
      fail "PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED expected=$EXPECTED_PARENT_RAW_MANIFEST_SHA256 actual=$ACTUAL_PARENT_RAW_MANIFEST_SHA256"
    fi
  fi
fi

# --- 12. Projection registry: registry length matches claimed count ---
REG_COUNT=$(python3 -c "import json; d=json.load(open('$C03_MANIFEST')); print(len(d['authoritative_projections']))")
check "REGISTRY:projection_count" "$CANON_PROJ_COUNT" "$REG_COUNT"

# --- 13. Subject reachable ---
if git cat-file -e "$SUBJECT" 2>/dev/null; then pass "SUBJECT_REACHABLE"
else fail "SUBJECT_REACHABLE"; fi

# --- 14. CORRECTION03 raw hash manifest verifies (no self-reference) ---
C03_RAW=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/raw-sha256.txt"
if [ ! -f "$C03_RAW" ]; then
  fail "THIS_ACT_RAW_HASH_MANIFEST_EXISTS=false"
else
  if grep -q "$C03_RAW" "$C03_RAW"; then
    fail "RAW_HASH_MANIFEST_SELF_REFERENTIAL"
  else
    pass "RAW_HASH_MANIFEST_SELF_REFERENTIAL=false"
  fi
  HASH_OK=0; HASH_BAD=0
  while IFS=' ' read -r expected_hash relpath; do
    case "$expected_hash" in '#'*|'') continue ;; esac
    abs="$ROOT/.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/${relpath#./}"
    actual=$(sha256sum "$abs" 2>/dev/null | awk '{print $1}')
    if [ "$actual" = "$expected_hash" ]; then HASH_OK=$((HASH_OK+1))
    else HASH_BAD=$((HASH_BAD+1))
         fail "THIS_ACT_HASH_MISMATCH:$relpath expected=$expected_hash actual=$actual"
    fi
  done < "$C03_RAW"
  if [ "$HASH_BAD" = 0 ] && [ "$HASH_OK" -gt 0 ]; then
    pass "RAW_HASHES_VERIFY=true ($HASH_OK verified)"
  else
    fail "RAW_HASHES_VERIFY=false ok=$HASH_OK bad=$HASH_BAD"
  fi
fi

# --- 15. Verifier-count self-consistency (no stale 28/28 or 47/47 text) ---
# Only check files that assert a current-state verifier count. Historical
# narrative prose (e.g. epic-board describing prior ACT results) is exempt
# because it deliberately records the older counts.
check_py "NO_STALE_VERIFIER_COUNT_TEXT" "PASS" "
import re
files = ['$C03_NORM','$C03_EVID/RESULT.md','$C03_EVID/MANIFEST.md']
bad = []
for f in files:
  try:
    t = open(f).read()
  except FileNotFoundError:
    continue
  for m in re.finditer(r'\b(\d+)/(\d+)\s*PASS\b', t):
    a, b = int(m.group(1)), int(m.group(2))
    if (a, b) in [(28, 28), (47, 47)]:
      bad.append((f, m.group(0)))
print('PASS' if not bad else f'FAIL:{bad}')"

# ============================================================
# POST-COMMIT (POSTCOMMIT) PREDICATES
# ============================================================
CONTENT_COMMIT=""
CONTENT_TREE_SHA=""
WORKING_TREE_CLEAN_AT_MEASUREMENT=""

if [ "$MODE" = "postcommit" ]; then
  # CONTENT_COMMIT_SHA must be supplied by caller (via env or argument).
  CONTENT_COMMIT="${CONTENT_COMMIT_SHA:-${C03_CONTENT_COMMIT:-}}"
  if [ -z "$CONTENT_COMMIT" ]; then
    CONTENT_COMMIT="$PARENT_COMMIT"
  fi

  HEAD_SHA=$(git rev-parse HEAD)
  check "HEAD_EQUALS_CONTENT_COMMIT" "$CONTENT_COMMIT" "$HEAD_SHA"

  CONTENT_TREE_SHA=$(git rev-parse "$HEAD_SHA^{tree}")
  pass "CONTENT_TREE_SHA_RECORDED (=$CONTENT_TREE_SHA)"

  WT=$(git status --short | wc -l | tr -d ' ')
  # Exclude:
  #   - raw-sha256.txt (regenerated, will be in Commit B)
  #   - build_raw_sha256.sh (the build script, not part of evidence)
  #   - freeze_postcommit.sh (the freeze script)
  #   - postcommit/* (the captured evidence, will be in Commit B)
  #   - POST-COMMIT-ATTESTATION.md (populated by Commit B)
  #   - epic-board.md (transition to CLOSED by Commit B)
  #   - precommit/verifier.{stdout,stderr,exitcode} (rewritten by
  #     freeze_precommit.sh which runs as part of the verification)
  WT_TRACKED_DIRTY=$(git diff --name-only \
    | grep -v -E '\.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/raw-sha256\.txt$' \
    | grep -v -E '\.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/build_raw_sha256\.sh$' \
    | grep -v -E '\.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/POST-COMMIT-ATTESTATION\.md$' \
    | grep -v -E '\.factory/epic-board\.md$' \
    | grep -v -E '\.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/precommit/verifier\.(stdout|stderr|exitcode)$' \
    | wc -l | tr -d ' ')
  WT_CACHED_DIRTY=$(git diff --cached --name-only | wc -l | tr -d ' ')
  WT_OTHER_UNTRACKED=$(git ls-files --others --exclude-standard \
    | grep -v -E '^\.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/' \
    | grep -v -E '^\.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/freeze_postcommit\.sh$' \
    | wc -l | tr -d ' ')
  WT_REAL=$((WT_TRACKED_DIRTY + WT_CACHED_DIRTY + WT_OTHER_UNTRACKED))
  if [ "$WT_REAL" = 0 ]; then
    WORKING_TREE_CLEAN_AT_MEASUREMENT=true
    pass "POST_COMMIT_WORKTREE_CLEAN (raw=$WT, considered=$WT_REAL)"
  else
    WORKING_TREE_CLEAN_AT_MEASUREMENT=false
    fail "POST_COMMIT_WORKTREE_CLEAN (raw=$WT, considered=$WT_REAL; tracked_dirty=$WT_TRACKED_DIRTY, cached_dirty=$WT_CACHED_DIRTY, other_untracked=$WT_OTHER_UNTRACKED)"
  fi

  # Commit scope factory-only
  SCOPE_NONFAC=$(git diff --name-only "$PARENT_COMMIT..$HEAD_SHA" | grep -v -E '^\.factory/' | wc -l | tr -d ' ')
  check "CONTENT_COMMIT_SCOPE_FACTORY_ONLY" "0" "$SCOPE_NONFAC"

  # Evidence resolves from HEAD
  for f in "$FAIL" "$INV" "$RES" "$CLSUM" "$CL02" "$CL03" \
           "$C03_MANIFEST" "$C03_NORM" "$C03_EVID/MANIFEST.md" \
           "$C03_EVID/RESULT.md" "$C03_EVID/AUTHORITY-MODEL.md" \
           "$C03_EVID/PROJECTION-AUDIT.md"; do
    if git cat-file -e "$HEAD_SHA:$f" 2>/dev/null; then
      pass "EVIDENCE_RESOLVES_FROM_CONTENT_COMMIT: $(basename "$f")"
    else
      fail "EVIDENCE_DOES_NOT_RESOLVE_FROM_CONTENT_COMMIT: $f"
    fi
  done

  # Board state must agree with ACT state machine projection.
  # Either CLOSED (at the attestation commit) or CLOSED_PENDING_ATTESTATION
  # (at the content commit) is a valid state for this ACT.
  # In postcommit mode, the board is read from the HEAD's tree (not
  # working tree) so we verify the committed state.
  if [ "$MODE" = "postcommit" ]; then
    # Read the committed board into a temp file the python heredoc can read.
    EPIC_FOR_PYTHON="/tmp/.c03_epic_committed_$$"
    git show "$HEAD_SHA:.factory/epic-board.md" > "$EPIC_FOR_PYTHON"
  else
    EPIC_FOR_PYTHON="$EPIC"
  fi
  check_py "BOARD_STATE_AGREES_WITH_ACT_STATE" "PASS" "
import re
t = open('$EPIC_FOR_PYTHON').read()
m = re.search(r'SWAMP-CHARACTERIZE-REST01-CORRECTION03\s*\|\s*(\S+)', t)
if not m: print('NO_ROW'); raise SystemExit
state = m.group(1).strip()
ok = (state in ('CLOSED','CLOSED_PENDING_ATTESTATION'))
print('PASS' if ok else f'FAIL:{state}')"
  # Cleanup temp file if we created one
  if [ "$MODE" = "postcommit" ]; then
    rm -f "$EPIC_FOR_PYTHON"
  fi

  # Postcommit manifest entry must bind subject commit
  check_py "ATTESTATION_SUBJECT_BOUND" "PASS" "
import json
m = json.load(open('$C03_MANIFEST'))
print('PASS' if (m.get('subject') and m.get('parent_commit')) else 'FAIL')"
fi

# ============================================================
# FINAL MACHINE PROJECTION (deterministic lines)
# ============================================================
echo
echo "VERIFIER_TOTAL=$TOTAL"
echo "VERIFIER_PASS=$PASS_COUNT"
echo "VERIFIER_FAIL=$FAIL_COUNT"
if [ "$FAIL_COUNT" = 0 ]; then
  echo "VERIFIER_RESULT=PASS"
else
  echo "VERIFIER_RESULT=FAIL"
fi
echo "PARENT_CHARACTERIZATION_RAW_MANIFEST_EXPECTED_SHA256=${EXPECTED_PARENT_RAW_MANIFEST_SHA256:-UNAVAILABLE}"
echo "PARENT_CHARACTERIZATION_RAW_MANIFEST_ACTUAL_SHA256=${ACTUAL_PARENT_RAW_MANIFEST_SHA256:-UNAVAILABLE}"
echo "PARENT_CHARACTERIZATION_RAW_MANIFEST_PRESERVED=$([ "$FAIL_COUNT" = 0 ] && echo true || echo false)"
if [ "$MODE" = "postcommit" ]; then
  echo "CONTENT_COMMIT_SHA=${CONTENT_COMMIT}"
  echo "CONTENT_TREE_SHA=${CONTENT_TREE_SHA}"
  echo "WORKING_TREE_CLEAN_AT_MEASUREMENT=${WORKING_TREE_CLEAN_AT_MEASUREMENT}"
fi

# Conservation invariant on verifier counts (defense in depth)
if [ "$((PASS_COUNT+FAIL_COUNT))" != "$TOTAL" ]; then
  echo "FAIL: VERIFIER_COUNTS_DO_NOT_CONSERVE" >&2
  exit 1
fi

if [ "$FAIL_COUNT" = 0 ]; then
  exit 0
else
  exit 1
fi
