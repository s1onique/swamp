#!/usr/bin/env bash
set -u
cd /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/swamp
export HOME=/tmp/swamp-char-rest01.ipyvth/home
export DENO_DIR=/tmp/swamp-char-rest01.ipyvth/deno
export TMPDIR=/tmp
START=$(date +%s)
/tmp/deno-arm64/deno cache --reload main.ts >/tmp/prewarm.stdout 2>/tmp/prewarm.stderr
RC=$?
END=$(date +%s)
echo $((END-START)) > /tmp/prewarm.duration
echo $RC > /tmp/prewarm.exitcode
echo 'prewarm complete'
