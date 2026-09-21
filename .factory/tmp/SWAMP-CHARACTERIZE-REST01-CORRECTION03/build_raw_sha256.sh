#!/usr/bin/env bash
# Generate raw-sha256.txt under .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
# hashing every authoritative raw-evidence file in that directory tree,
# EXCLUDING raw-sha256.txt itself (no self-reference).
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SCRIPT_DIR = <repo>/.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03
# 4 levels up = repo root
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"
OUT="$ROOT/$RAW_TREE_REL/raw-sha256.txt"

cd "$ROOT"
TMP_HASHES=$(mktemp)
trap "rm -f $TMP_HASHES" EXIT

# Hash every regular file in the raw tree, deterministically, excluding
# raw-sha256.txt itself AND the verifier stdout/stderr/exitcode files
# (those change on every verifier run and would cause a chicken-and-egg
# when the verifier itself is verifying the manifest).
# Paths in the manifest are RELATIVE TO THE RAW TREE ROOT so the verifier
# can resolve them from C03_RAW directly.
find "$RAW_TREE_REL" -type f \
  ! -name "raw-sha256.txt" \
  ! -name "build_raw_sha256.sh" \
  ! -name "verifier.stdout" \
  ! -name "verifier.stderr" \
  ! -name "verifier.exitcode" \
  ! -name "freeze_precommit.sh" \
  ! -name "freeze_postcommit.sh" \
  ! -name "before.txt" \
  ! -name "mutated.txt" \
  ! -name "restored.txt" \
  ! -path "*/postcommit/environment.txt" \
  ! -path "*/postcommit/status.txt" \
  ! -path "*/precommit/environment.txt" \
  | LC_ALL=C sort \
  | while IFS= read -r f; do
      h=$(sha256sum "$f" | awk '{print $1}')
      rel="${f#${RAW_TREE_REL}/}"
      printf '%s  %s\n' "$h" "$rel"
    done > "$TMP_HASHES"

# Replace the manifest atomically. We DO NOT include our own name.
mv "$TMP_HASHES" "$OUT"

# Sanity: the manifest must not reference itself.
if grep -q "raw-sha256.txt" "$OUT"; then
  echo "FAIL: manifest contains self-reference" >&2
  exit 1
fi

# Sanity: every entry must be verifiable.
while IFS=' ' read -r expected_hash relpath; do
  case "$expected_hash" in '#'*|'') continue ;; esac
  actual=$(sha256sum "$RAW_TREE_REL/$relpath" | awk '{print $1}')
  if [ "$actual" != "$expected_hash" ]; then
    echo "FAIL: $RAW_TREE_REL/$relpath expected=$expected_hash actual=$actual" >&2
    exit 1
  fi
done < "$OUT"

echo "raw-sha256.txt built; entries=$(grep -cv '^#\|^$' "$OUT")"
