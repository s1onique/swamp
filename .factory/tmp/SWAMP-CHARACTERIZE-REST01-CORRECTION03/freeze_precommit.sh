#!/usr/bin/env bash
# freeze precommit evidence:
#   1. run verifier (captures to precommit/verifier.{stdout,stderr,exitcode})
#   2. immediately rebuild raw-sha256.txt to capture the now-current hashes
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RAW_TREE_REL=".factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03"

cd "$ROOT"

# step 1: run verifier, capture
bash "$ROOT/.factory/scripts/check_characterize_rest01_correction03.sh" --mode precommit \
  1>"$RAW_TREE_REL/precommit/verifier.stdout" \
  2>"$RAW_TREE_REL/precommit/verifier.stderr"
echo "$?" > "$RAW_TREE_REL/precommit/verifier.exitcode"

# step 2: rebuild manifest
bash "$RAW_TREE_REL/build_raw_sha256.sh"
echo "freeze_precommit :: DONE"
