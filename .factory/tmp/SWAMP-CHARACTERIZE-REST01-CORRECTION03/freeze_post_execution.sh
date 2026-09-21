#!/usr/bin/env bash
# freeze_post_execution.sh
#
# CORRECTION07: machine B in the post-execution-authority architecture.
# Reads ONLY the committed tree (git cat-file). Evaluates the 8
# deferred properties against the frozen terminal_run/ bundle.
#
# This is the post-execution VERIFIER (the producer → evidence →
# verifier separation). The terminal verifier emitted those 8
# properties as DEFERRED (per CORRECTION07 D1). This verifier is
# the only authority that may pass or fail them.
#
# Inputs:
#   - the committed tree (already captured in commit D)
#   - the terminal_run/ subdirectory committed in the SAME commit
# Outputs (committed in .factory/tmp/.../post_execution/):
#   verifier.stdout     the post-execution verifier's stdout
#   verifier.stderr     the post-execution verifier's stderr
#   verifier.exitcode   0 if 8/8 PASS, 1 otherwise
#   verifier.sha256     sha256 of the verifier script
#   head.txt            git rev-parse HEAD at capture time
#   tree.txt            git rev-parse HEAD^{tree} at capture time
#   environment.txt     context metadata

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"
PE="$ROOT/$RAW_TREE_REL/post_execution"

cd "$ROOT"

# Stage 1: build in a temp dir to avoid corrupting the working tree.
BUILD_PE=$(mktemp -d)
cleanup() { rm -rf "$BUILD_PE"; }
trap cleanup EXIT

HEAD_SHA=$(git rev-parse HEAD)
HEAD_TREE_SHA=$(git rev-parse "HEAD^{tree}")

# Stage 2: capture committed-tree bytes to seed the post_execution
# bundle with the same provenance invariants as terminal_run/.
git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$RAW_TREE_REL/terminal_run/head.txt" 2>/dev/null | awk '{print $3}' | head -1)" > "$BUILD_PE/head.txt" 2>/dev/null || printf '%s\n' "$HEAD_SHA" > "$BUILD_PE/head.txt"
git cat-file blob "$(git ls-tree "$HEAD_SHA" -- "$RAW_TREE_REL/terminal_run/tree.txt" 2>/dev/null | awk '{print $3}' | head -1)" > "$BUILD_PE/tree.txt" 2>/dev/null || printf '%s\n' "$HEAD_TREE_SHA" > "$BUILD_PE/tree.txt"
sha256sum .factory/scripts/check_characterize_rest01_correction03.sh > "$BUILD_PE/verifier.sha256"

# Stage 3: run the post-execution verifier. Reads committed tree
# ONLY — does not depend on on-disk working copy state.
bash "$ROOT/.factory/scripts/check_characterize_rest01_correction03.sh" --mode post-exec \
  1>"$BUILD_PE/verifier.stdout" \
  2>"$BUILD_PE/verifier.stderr"
EC=$?
printf '%s\n' "$EC" > "$BUILD_PE/verifier.exitcode" 2>/dev/null || echo "$EC" > "$BUILD_PE/verifier.exitcode"

# Stage 4: capture environment for context.
cat > "$BUILD_PE/environment.txt" <<TXT
captured_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
deno_version_recorded=2.9.7 (pinned in .tool-versions; not on PATH for this shell)
deno_on_path=$([ -n "$(command -v deno 2>/dev/null || true)" ] && echo yes || echo no)
os=$(uname -a)
subject_sha=a392c49e1c899fbbbbf39bf84d73a8308c048eb6
invocation=check_characterize_rest01_correction03.sh --mode post-exec
TXT

# Stage 5: atomically move BUILD_PE into post_execution/.
mkdir -p "$PE"
rm -f "$PE"/*
mv "$BUILD_PE"/* "$PE"/
rmdir "$BUILD_PE"
trap - EXIT

echo "freeze_post_execution :: DONE"
echo "POST_EXEC_EXITCODE=$EC"
echo "POST_EXEC_HEAD_SHA=$(head -1 "$PE/head.txt")"
echo "POST_EXEC_TREE_SHA=$(head -1 "$PE/tree.txt")"
