#!/bin/bash
set -u
cd /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/swamp
export HOME=/tmp/swamp-char-rest01.ipyvth/home
export DENO_DIR=/tmp/swamp-char-rest01.ipyvth/deno
export TMPDIR=/tmp
export SWAMP_NO_TELEMETRY=1
set +e
/tmp/deno-arm64/deno test --allow-read --allow-write --allow-env --allow-run --allow-net --allow-sys --allow-ffi integration/remote_execution_test.ts 2>"$PWD/CLUSTER-02/isolation-stderr.txt" 1>"$PWD/CLUSTER-02/isolation-stdout.txt"
RC=$?
set -e
echo $RC > "$PWD/CLUSTER-02/isolation-exitcode.txt"
echo "exit=$RC"
