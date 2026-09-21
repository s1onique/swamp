#!/usr/bin/env bash
# freeze_terminal_run.sh
#
# CORRECTION08: acyclic terminal-run freeze.
# This script runs the verifier ONCE while HEAD == C8 (the immutable
# subject commit). The verifier output becomes the terminal_run/ bundle
# which is then folded into C8 itself (via `git commit --amend`).
# C8 is the SUBJECT; C8 carries its own evidence (terminal_run/ inside
# C8's tree). A8 (a descendant commit) carries only the post-execution
# cross-check, never authority over C8.
#
# CRITICAL: this script verifies HEAD == C8 before doing anything.
# If HEAD != C8, the script refuses to run. This prevents accidental
# cycles (running the verifier against the attestation commit A8
# instead of the subject commit C8).
#
# Outputs at terminal_run/:
#   head.txt          == committed postcommit/head.txt (== C8 SHA)
#   tree.txt          == committed postcommit/tree.txt (== C8 tree)
#   verifier.exitcode == exit code of the terminal verifier run
#   verifier.stdout   stdout of the terminal verifier run
#   verifier.stderr   stderr of the terminal verifier run
#   verifier.sha256   sha256 of the verifier script
#   manifest.txt      machine-readable verifier scalars (CORRECTION08)
#   environment.txt   context metadata

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"
PC="$ROOT/$RAW_TREE_REL/postcommit"
TR="$ROOT/$RAW_TREE_REL/terminal_run"

cd "$ROOT"

HEAD_SHA=$(git rev-parse HEAD)

# CORRECTION08 acyclic enforcement: refuse to run unless HEAD is the
# immutable subject commit. The subject C8 should be passed as the
# first argument. If not provided, default to HEAD~1 (which is the
# expected subject when freeze_terminal_run is called between the C8
# commit and the A8 commit).
SUBJECT_C8="${1:-${FREEZE_SUBJECT_C8:-HEAD~1}}"
EXPECTED_HEAD=$(git rev-parse "$SUBJECT_C8" 2>/dev/null || echo "")
if [ -z "$EXPECTED_HEAD" ]; then
  echo "FAIL: subject C8=$SUBJECT_C8 is not a valid git object" >&2
  exit 2
fi
if [ "$HEAD_SHA" != "$EXPECTED_HEAD" ]; then
  echo "FAIL: acyclic architecture violated. HEAD=$HEAD_SHA but expected subject C8=$EXPECTED_HEAD" >&2
  echo "       freeze_terminal_run.sh must be invoked while HEAD == C8." >&2
  exit 2
fi
echo "freeze_terminal_run :: acyclic check PASS (HEAD=$HEAD_SHA == C8=$EXPECTED_HEAD)"

# Stage 1: capture the stable committed binary evidence in BUILD (out-of-tree).
# CORRECTION08 acyclic: capture the verifier SHA directly from C8's tree
# (HEAD == C8), since the postcommit/verifier.sha256 might be stale
# (it was captured when HEAD was the previous cycle's A7).
BUILD_TR=$(mktemp -d)
cleanup() { rm -rf "$BUILD_TR"; }
trap cleanup EXIT

# Compute the verifier SHA from C8's tree (the live state at freeze time).
VERIFIER_BLOB=$(git ls-tree "$HEAD_SHA" -- .factory/scripts/check_characterize_rest01_correction03.sh 2>/dev/null | awk '{print $3}' | head -1)
if [ -n "$VERIFIER_BLOB" ]; then
  git cat-file blob "$VERIFIER_BLOB" 2>/dev/null | sha256sum | awk '{print $1 "  .factory/scripts/check_characterize_rest01_correction03.sh"}' > "$BUILD_TR/verifier.sha256"
else
  # Fallback: use committed postcommit/verifier.sha256
  if [ -z "$(git ls-tree "$HEAD_SHA" -- "$PC/head.txt" 2>/dev/null | awk '{print $3}')" ]; then
    cp "$PC/verifier.sha256" "$BUILD_TR/verifier.sha256"
  else
    git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$PC/verifier.sha256" | awk '{print $3}')" > "$BUILD_TR/verifier.sha256"
  fi
fi

if [ -z "$(git ls-tree "$HEAD_SHA" -- "$PC/head.txt" 2>/dev/null | awk '{print $3}')" ]; then
  # Not yet committed; use on-disk source.
  cp "$PC/head.txt"         "$BUILD_TR/head.txt"
  cp "$PC/tree.txt"         "$BUILD_TR/tree.txt"
else
  git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$PC/head.txt" | awk '{print $3}')" > "$BUILD_TR/head.txt"
  git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$PC/tree.txt" | awk '{print $3}')" > "$BUILD_TR/tree.txt"
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
subject_sha=$EXPECTED_HEAD
invocation=$(echo "check_characterize_rest01_correction03.sh --mode terminal (CORRECTION08 acyclic: subject=C8)")
acyclic_check=PASS
TXT

# CORRECTION08: machine-readable verifier scalars in terminal_run/manifest.txt.
{
  echo "# terminal_run manifest (CORRECTION08 acyclic)"
  echo "SUBJECT_C8=$EXPECTED_HEAD"
  echo "CAPTURED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # Extract machine lines from verifier.stdout (deterministic format)
  grep -E '^VERIFIER_(TOTAL|PASS|FAIL|DEFERRED|RESULT)=' "$BUILD_TR/verifier.stdout" || true
} > "$BUILD_TR/manifest.txt"

# Stage 4: atomically move BUILD_TR into terminal_run/.
mkdir -p "$TR"
rm -f "$TR"/*
mv "$BUILD_TR"/* "$TR"/
rmdir "$BUILD_TR"
trap - EXIT

# CORRECTION08: compute BUNDLE_V1 hash over the 7 lex-ordered terminal_run/
# files (excluding manifest.txt which is metadata, not evidence) and
# append it to manifest.txt. This is the same hash the verifier computes
# in P5; we record it here for visibility and to avoid the manifest
# referencing a hash that doesn't exist yet (chicken-and-egg).
#
# Format MUST match what the verifier re-derives: each line is
# `terminal_run/=<raw content bytes>\n`. (The verifier re-derives
# this format from `git cat-file blob` to ensure byte-identity.)
TMP=$(mktemp)
{
  printf 'BUNDLE_V1\n'
  for f in $(ls -1 "$TR" | grep -v '^manifest\.txt$' | sort); do
    printf 'terminal_run/%s=' "$f"
    cat "$TR/$f"
    printf '\n'
  done
} > "$TMP"
BUNDLE_HASH=$(sha256sum "$TMP" | awk '{print $1}')
rm -f "$TMP"
echo "TERMINAL_BUNDLE_HASH=$BUNDLE_HASH" >> "$TR/manifest.txt"

# CORRECTION08: compute TERMINAL_RUN_ID (TV_RUN_V2_C08) and append to manifest.txt.
# CORRECTION08 acyclic: TV_RUN_V2_C08 has 5 versioned fields (NOT 6 or 7 as
# in CORRECTION06/07). The content_commit and verifier_sha256 fields are
# omitted because both are part of C8 itself, and writing the
# terminal_run/ bundle AND amending C8 changes both. Including either
# would create a chicken-and-egg where TVRID changes every time C8 is
# amended. Instead, the subject reference is captured separately
# (SUBJECT_C8 in manifest.txt; the verifier's --subject argument binds
# it) and the verifier_sha256 is recorded in terminal_run/verifier.sha256
# (verified by the bundle hash P5).
TV_RUN_TMP=$(mktemp)
{
  printf '%s\n' "TV_RUN_V2_C08"
  printf 'bundle_sha256=%s\n' "$BUNDLE_HASH"
  printf 'stdout_sha256=%s\n' "$(sha256sum "$TR/verifier.stdout" | awk '{print $1}')"
  printf 'stderr_sha256=%s\n' "$(sha256sum "$TR/verifier.stderr" | awk '{print $1}')"
  printf 'exitcode=%s\n' "$(cat "$TR/verifier.exitcode" | tr -d ' \t\n')"
  printf 'execution_mode=terminal\n'
} > "$TV_RUN_TMP"
TV_RUN_ID=$(sha256sum "$TV_RUN_TMP" | awk '{print $1}')
rm -f "$TV_RUN_TMP"
echo "TERMINAL_RUN_ID=$TV_RUN_ID" >> "$TR/manifest.txt"

echo "freeze_terminal_run :: DONE"
echo "TERMINAL_EXITCODE=$EC"
echo "TERMINAL_HEAD_SHA=$(head -1 "$TR/head.txt")"
echo "TERMINAL_TREE_SHA=$(head -1 "$TR/tree.txt")"
echo "TERMINAL_BUNDLE_HASH=$BUNDLE_HASH"
echo "TERMINAL_RUN_ID=$TV_RUN_ID"
