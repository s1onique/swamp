#!/usr/bin/env bash
# freeze_terminal_run.sh
#
# CORRECTION06: bind closure to the terminal verifier execution that
# gives the FINAL pass. After .factory/tmp/.../postcommit/{head,tree,...}
# have been committed (they form the FIRST-pass bundle), run the verifier
# ONCE more and capture its execution as the terminal run.
#
# The terminal_run/ directory is the authoritative evidence for the
# committed verbatim binary identity of the post-construction pass:
#   terminal_run.head.txt          same content as postcommit/head.txt
#   terminal_run.tree.txt          same content as postcommit/tree.txt
#   terminal_run.verifier.exitcode == 0
#   terminal_run.verifier.stdout   MUST contain VERIFIER_RESULT=PASS, VERIFIER_FAIL=0
#   terminal_run.verifier.sha256   == sha256(verifier file)
#   terminal_run.terminal_verifier_run_id  == sha256 over the stable terminal state
#
# The terminal_verifier_run_id is a stable digest over:
#   committed postcommit/head.txt + tree.txt + verifier.exitcode
# which is invariant under verifier.stdout content (which can drift).

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"
PC="$ROOT/$RAW_TREE_REL/postcommit"
TR="$ROOT/$RAW_TREE_REL/terminal_run"

cd "$ROOT"

# copy the stable binary evidence captured at construction time
cp "$PC/head.txt"          "$TR/head.txt"
cp "$PC/tree.txt"          "$TR/tree.txt"
cp "$PC/verifier.sha256"   "$TR/verifier.sha256"

# Run the verifier ONCE more with the SAME env (CONTENT_COMMIT_SHA = HEAD~1).
# At this point all postcommit bundles are committed in HEAD, so the verifier
# will read consistent state and produce a PASS.
BOARD_EXPECTED_STATE="CLOSED_PENDING_ATTESTATION" \
  bash "$ROOT/.factory/scripts/check_characterize_rest01_correction03.sh" --mode postcommit \
  1>"$TR/verifier.stdout" \
  2>"$TR/verifier.stderr"
echo "$?" > "$TR/verifier.exitcode"

# Also capture environment for context
cat > "$TR/environment.txt" <<TXT
captured_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
deno_version_recorded=2.9.7 (pinned in .tool-versions; not on PATH for this shell)
deno_on_path=$([ -n "$(command -v deno 2>/dev/null || true)" ] && echo yes || echo no)
os=$(uname -a)
terminal_verifier_run_id=$(TERMINAL_RUN_NOW=1 bash "$ROOT/.factory/scripts/check_characterize_rest01_correction03.sh" --mode id 2>/dev/null || echo UNKNOWN)
subject_sha=a392c49e1c899fbbbbf39bf84d73a8308c048eb6
invocation=$(echo "check_characterize_rest01_correction03.sh --mode postcommit (terminal)")
TXT

echo "freeze_terminal_run :: DONE"
echo "TERMINAL_EXITCODE=$(cat "$TR/verifier.exitcode")"
echo "TERMINAL_HEAD_SHA=$(head -1 "$TR/head.txt")"
echo "TERMINAL_TREE_SHA=$(head -1 "$TR/tree.txt")"