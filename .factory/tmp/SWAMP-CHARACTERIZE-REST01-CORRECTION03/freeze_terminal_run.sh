#!/usr/bin/env bash
# freeze_terminal_run.sh
#
# CORRECTION06: bind closure to the terminal verifier execution that
# gives the FINAL pass. After .factory/tmp/.../postcommit/{head,tree,...}
# have been committed (D6), run the verifier ONCE more and capture its
# execution as the terminal run.
#
# Uses a build directory BUILD_TR (e.g. /tmp/...freeze_$$) so the working
# tree stays clean during the verifier run; only the finalised bundles
# are atomically moved into terminal_run/ at the very end.
#
# Outputs at terminal_run/:
#   head.txt          == committed postcommit/head.txt
#   tree.txt          == committed postcommit/tree.txt
#   verifier.exitcode == exit code of the terminal verifier run
#   verifier.stdout   stdout of the terminal verifier run
#   verifier.stderr   stderr of the terminal verifier run
#   verifier.sha256   sha256 of the verifier script
#   environment.txt   context metadata

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"
PC="$ROOT/$RAW_TREE_REL/postcommit"
TR="$ROOT/$RAW_TREE_REL/terminal_run"

cd "$ROOT"

HEAD_SHA=$(git rev-parse HEAD)

# Stage 1: capture the stable committed binary evidence in BUILD (out-of-tree).
# CORRECTION07: prefer COMMITTED postcommit/* blobs from HEAD's tree
# (the canonical source of truth); fall back to on-disk postcommit/*
# when not yet committed (C7 still being authored; D7 not yet made).
BUILD_TR=$(mktemp -d)
cleanup() { rm -rf "$BUILD_TR"; }
trap cleanup EXIT

if [ -z "$(git ls-tree "$HEAD_SHA" -- "$PC/head.txt" 2>/dev/null | awk '{print $3}')" ]; then
  # Not yet committed; use on-disk source.
  cp "$PC/head.txt"         "$BUILD_TR/head.txt"
  cp "$PC/tree.txt"         "$BUILD_TR/tree.txt"
  cp "$PC/verifier.sha256"  "$BUILD_TR/verifier.sha256"
else
  git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$PC/head.txt" | awk '{print $3}')" > "$BUILD_TR/head.txt"
  git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$PC/tree.txt" | awk '{print $3}')" > "$BUILD_TR/tree.txt"
  git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$PC/verifier.sha256" | awk '{print $3}')" > "$BUILD_TR/verifier.sha256"
fi

# Stage 2: run the verifier with redirected stdout/stderr into BUILD_TR.
BOARD_EXPECTED_STATE="CLOSED_PENDING_ATTESTATION" \
  bash "$ROOT/.factory/scripts/check_characterize_rest01_correction03.sh" --mode terminal \
  1>"$BUILD_TR/verifier.stdout" \
  2>"$BUILD_TR/verifier.stderr"
EC=$?
echo "$EC" > "$BUILD_TR/verifier.exitcode"

# Stage 3: capture environment for context.
cat > "$BUILD_TR/environment.txt" <<TXT
captured_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
deno_version_recorded=2.9.7 (pinned in .tool-versions; not on PATH for this shell)
deno_on_path=$([ -n "$(command -v deno 2>/dev/null || true)" ] && echo yes || echo no)
os=$(uname -a)
subject_sha=a392c49e1c899fbbbbf39bf84d73a8308c048eb6
invocation=$(echo "check_characterize_rest01_correction03.sh --mode postcommit (terminal)")
TXT

# Stage 4: atomically move BUILD_TR into terminal_run/.
mkdir -p "$TR"
rm -f "$TR"/*
mv "$BUILD_TR"/* "$TR"/
rmdir "$BUILD_TR"
trap - EXIT

echo "freeze_terminal_run :: DONE"
echo "TERMINAL_EXITCODE=$EC"
echo "TERMINAL_HEAD_SHA=$(head -1 "$TR/head.txt")"
echo "TERMINAL_TREE_SHA=$(head -1 "$TR/tree.txt")"
