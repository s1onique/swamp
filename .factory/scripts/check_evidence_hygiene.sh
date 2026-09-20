#!/usr/bin/env bash
# Scoped evidence-hygiene check.
#
# Policy (codified by CORRECTION02):
#   .factory/tmp/**                     -> raw evidence, immutable, exempt
#   .factory/evidence/**                -> authored, hygiene-checked
#   .factory/evidence/**/normalized/**  -> authored derivative, hygiene-checked
#   .factory/acts/**                    -> authored, hygiene-checked
#   .factory/epic-board.md              -> authored, hygiene-checked
#
# This script checks the authored subset only and reports raw-evidence
# whitespace as EXPECTED_FAIL_RAW_EVIDENCE (not an error).

set -u

RANGE="${1:-HEAD~1..HEAD}"

# Whole-range check (raw evidence included).
WHOLE=$(git diff --check "$RANGE" 2>&1 || true)

# Authored-artifact check (raw evidence excluded).
AUTHORED_FILES=$(git diff --name-only "$RANGE" \
  | grep '^\.factory/' \
  | grep -v '^\.factory/tmp/' || true)

AUTHORED_VIOLATIONS=""
if [ -n "$AUTHORED_FILES" ]; then
  AUTHORED_VIOLATIONS=$(echo "$AUTHORED_FILES" \
    | xargs -I{} git diff --check "$RANGE" -- {} 2>&1 || true)
fi

# Raw SHA256 invariants (raw evidence must not have drifted).
RAW_SHA=$(sha256sum .factory/tmp/native-baseline/test.stdout 2>/dev/null \
  | awk '{print $1}')
BASELINE01_SHA=$(git show 4a2c946f:.factory/tmp/native-baseline/test.stdout \
  | sha256sum | awk '{print $1}')

# Output.
if [ -z "$WHOLE" ]; then
  echo "WHOLE_RANGE_DIFF_CHECK=PASS"
  echo "WHOLE_RANGE_WHITESPACE_ERRORS=0"
else
  echo "WHOLE_RANGE_DIFF_CHECK=EXPECTED_FAIL_RAW_EVIDENCE"
  echo "WHOLE_RANGE_WHITESPACE_ERRORS=$(printf '%s\n' "$WHOLE" | grep -c .)"
  echo "WHOLE_RANGE_DETAIL:"
  printf '%s\n' "$WHOLE" | sed 's/^/  /'
fi
if [ -z "$AUTHORED_VIOLATIONS" ]; then
  echo "AUTHORED_ARTIFACTS_DIFF_CHECK=PASS"
else
  echo "AUTHORED_ARTIFACTS_DIFF_CHECK=FAIL"
  echo "AUTHORED_ARTIFACTS_DETAIL:"
  printf '%s\n' "$AUTHORED_VIOLATIONS" | sed 's/^/  /'
fi
echo "AUTHORED_ARTIFACTS_CHECKED=$(if [ -n "$AUTHORED_FILES" ]; then printf '%s\n' "$AUTHORED_FILES" | grep -c .; else echo 0; fi)"
echo "RAW_EVIDENCE_SHA256=$RAW_SHA"
echo "BASELINE01_REFERENCE_SHA256=$BASELINE01_SHA"
if [ "$RAW_SHA" = "$BASELINE01_SHA" ]; then
  echo "RAW_EVIDENCE_SHA256_UNCHANGED=true"
else
  echo "RAW_EVIDENCE_SHA256_UNCHANGED=false"
fi
