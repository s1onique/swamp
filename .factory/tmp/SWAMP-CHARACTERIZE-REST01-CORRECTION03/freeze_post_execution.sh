#!/usr/bin/env bash
# freeze_post_execution.sh
#
# CORRECTION08: machine B in the acyclic attestation architecture.
# Reads ONLY the committed tree (git cat-file). Evaluates the 8
# deferred properties AGAINST THE SUBJECT (C8) — NOT against HEAD
# (which is A8, the attestation commit).
#
# CORRECTION07 originally framed this as the "post-execution verifier
# is the sole authority on the 8 deferred properties." CORRECTION08
# reframes it: the post-execution verifier in A8 is **informational
# cross-check evidence that A8 carries about C8**. The verdict
# authority on C8 is C8:terminal_run/verifier.stdout, not anything
# in A8.
#
# Inputs:
#   - the committed tree at A8 (already committed)
#   - C8 = the immutable subject, passed as $1 (default: HEAD~1)
# Outputs (committed in .factory/tmp/.../post_execution/):
#   verifier.stdout     the post-execution verifier's stdout (with --subject $C8)
#   verifier.stderr     the post-execution verifier's stderr
#   verifier.exitcode   0 if all invariants PASS, 1 otherwise
#   verifier.sha256     sha256 of the verifier script
#   head.txt            git rev-parse HEAD at capture time (= A8)
#   tree.txt            git rev-parse HEAD^{tree} at capture time (= A8 tree)
#   subject.txt         the C8 subject SHA (CORRECTION08 acyclic record)
#   environment.txt     context metadata

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"
PE="$ROOT/$RAW_TREE_REL/post_execution"

cd "$ROOT"

# CORRECTION08 acyclic enforcement: require explicit subject C8. Default
# to HEAD~1 (which is the expected subject when freeze_post_execution is
# called during the A8 commit step, immediately after C8 is the parent).
SUBJECT_C8="${1:-${FREEZE_SUBJECT_C8:-HEAD~1}}"
EXPECTED_SUBJECT=$(git rev-parse "$SUBJECT_C8" 2>/dev/null || echo "")
if [ -z "$EXPECTED_SUBJECT" ]; then
  echo "FAIL: subject C8=$SUBJECT_C8 is not a valid git object" >&2
  exit 2
fi
HEAD_SHA=$(git rev-parse HEAD)
HEAD_TREE_SHA=$(git rev-parse "HEAD^{tree}")
# CORRECTION08 partial acyclic check: HEAD must be a descendant of C8.
# We do NOT require HEAD == C8 (this script is called during the A8
# commit step, after C8 is committed; HEAD will become A8).
if ! git merge-base --is-ancestor "$EXPECTED_SUBJECT" "$HEAD_SHA" 2>/dev/null; then
  if [ "$(git rev-parse HEAD~1 2>/dev/null || echo NONE)" != "$EXPECTED_SUBJECT" ]; then
    echo "FAIL: subject C8=$EXPECTED_SUBJECT is not HEAD~1 and not an ancestor of HEAD=$HEAD_SHA" >&2
    exit 2
  fi
fi
echo "freeze_post_execution :: acyclic check PASS (subject C8=$EXPECTED_SUBJECT; HEAD=$HEAD_SHA; HEAD~1=$(git rev-parse HEAD~1 2>/dev/null || echo NONE))"

# Stage 1: build in a temp dir to avoid corrupting the working tree.
BUILD_PE=$(mktemp -d)
cleanup() { rm -rf "$BUILD_PE"; }
trap cleanup EXIT

# Stage 2: capture live HEAD/HEAD-tree at this moment (this IS the
# post-execution bundle's provenance invariant — it records WHO ran
# the post-exec verifier and what tree they ran against).
printf '%s\n' "$HEAD_SHA" > "$BUILD_PE/head.txt"
printf '%s\n' "$HEAD_TREE_SHA" > "$BUILD_PE/tree.txt"
printf '%s\n' "$EXPECTED_SUBJECT" > "$BUILD_PE/subject.txt"
sha256sum .factory/scripts/check_characterize_rest01_correction03.sh > "$BUILD_PE/verifier.sha256"

# Stage 3: run the post-execution verifier with --subject C8.
bash "$ROOT/.factory/scripts/check_characterize_rest01_correction03.sh" --mode post-exec --subject "$EXPECTED_SUBJECT" \
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
subject_sha=$EXPECTED_SUBJECT
attestor_sha=$HEAD_SHA
invocation=check_characterize_rest01_correction03.sh --mode post-exec --subject $EXPECTED_SUBJECT (CORRECTION08 acyclic)
verdict_role=INFORMATIONAL_CROSS_CHECK (CORRECTION08: the verdict authority on C8 is C8:terminal_run/verifier.stdout, not anything in this bundle)
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
