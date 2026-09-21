#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PARENT_COMMIT_SHA="$(cd "$MAIN_REPO" && git rev-parse HEAD)"
NEG_ROOT="/tmp/swamp-c03-projection-negative"
rm -rf "$NEG_ROOT"
mkdir -p "$NEG_ROOT"
git clone --quiet "$MAIN_REPO" "$NEG_ROOT/repo"
cd "$NEG_ROOT/repo"
git checkout --quiet "$PARENT_COMMIT_SHA"
mkdir -p .factory/scripts .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03 .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03
cp "$MAIN_REPO/.factory/scripts/check_characterize_rest01_correction03.sh" .factory/scripts/
cp -R "$MAIN_REPO/.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/." .factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
cp -R "$MAIN_REPO/.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/." .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/
cp "$MAIN_REPO/.factory/epic-board.md" .factory/epic-board.md
chmod +x .factory/scripts/check_characterize_rest01_correction03.sh
echo "cloned_head=$(git rev-parse HEAD)"
echo "setup_done"
