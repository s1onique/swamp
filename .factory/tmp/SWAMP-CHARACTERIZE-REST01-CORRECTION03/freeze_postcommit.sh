#!/usr/bin/env bash
# freeze postcommit evidence (after Commit A exists):
#   1. capture postcommit head/tree/status/environment/verifier.sha256
#   2. build raw-sha256.txt to capture CURRENT hashes (including
#      postcommit/head.txt, tree.txt, verifier.sha256)
#   3. run postcommit verifier — reads the now-current manifest and
#      captures verifier.{stdout,stderr,exitcode}
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"
PC="$ROOT/$RAW_TREE_REL/postcommit"

cd "$ROOT"

# step 1: capture head/tree/status/environment/verifier.sha256
git rev-parse HEAD > "$PC/head.txt"
git rev-parse HEAD^{tree} > "$PC/tree.txt"
git status --short > "$PC/status.txt"
sha256sum .factory/scripts/check_characterize_rest01_correction03.sh > "$PC/verifier.sha256"

cat > "$PC/environment.txt" <<TXT
captured_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
deno_version_recorded=2.9.7 (pinned in .tool-versions; not on PATH for this shell)
deno_on_path=$([ -n "$(command -v deno 2>/dev/null || true)" ] && echo yes || echo no)
os=$(uname -a)
content_commit_sha=$(git rev-parse HEAD)
content_tree_sha=$(git rev-parse HEAD^{tree})
subject_sha=a392c49e1c899fbbbbf39bf84d73a8308c048eb6
invocation=$(echo "check_characterize_rest01_correction03.sh --mode postcommit")
TXT

# step 2: rebuild manifest BEFORE running verifier so the verifier
# reads a manifest that matches the postcommit/ files it sees.
bash "$RAW_TREE_REL/build_raw_sha256.sh"

# step 3: run postcommit verifier
CONTENT_COMMIT_SHA=$(git rev-parse HEAD) \
  BOARD_EXPECTED_STATE="${BOARD_EXPECTED_STATE:-CLOSED_PENDING_ATTESTATION}" \
  bash "$ROOT/.factory/scripts/check_characterize_rest01_correction03.sh" --mode postcommit \
  1>"$PC/verifier.stdout" \
  2>"$PC/verifier.stderr"
echo "$?" > "$PC/verifier.exitcode"
echo "freeze_postcommit :: DONE"
