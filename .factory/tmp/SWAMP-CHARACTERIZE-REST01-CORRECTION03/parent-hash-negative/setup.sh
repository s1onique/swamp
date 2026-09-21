#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PARENT_COMMIT_SHA="$(cd "$MAIN_REPO" && git rev-parse HEAD)"
NEG_ROOT="/tmp/swamp-c03-parent-hash-negative"
rm -rf "$NEG_ROOT"
mkdir -p "$NEG_ROOT"
git clone --quiet "$MAIN_REPO" "$NEG_ROOT/repo"
cd "$NEG_ROOT/repo"
git checkout --quiet "$PARENT_COMMIT_SHA"
# Apply CORRECTION03 authored artifacts to the clone so the verifier can
# resolve them. (Not committed at parent commit yet.)
mkdir -p .factory/scripts .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03 .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03
cp "$MAIN_REPO/.factory/scripts/check_characterize_rest01_correction03.sh" .factory/scripts/
cp -R "$MAIN_REPO/.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/." .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
# Copy the FULL raw evidence tree so the manifest verifies cleanly.
cp -R "$MAIN_REPO/.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/." .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
cp "$MAIN_REPO/.factory/epic-board.md" .factory/epic-board.md
chmod +x .factory/scripts/check_characterize_rest01_correction03.sh
echo "cloned_head=$(git rev-parse HEAD)"
echo "manifest_present=$(test -f .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/manifest.json && echo yes || echo no)"
echo "raw_sha_present=$(test -f .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/raw-sha256.txt && echo yes || echo no)"
echo "setup_done"
