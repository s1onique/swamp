#!/usr/bin/env bash
# Wrapper that runs the CORRECTION02 verifier from repo root.
# All paths inside the verifier are relative; the wrapper
# changes to the directory two levels up from this script.
cd "$(dirname "$0")/../../../.."
bash .factory/scripts/check_characterize_rest01_correction02.sh
