#!/usr/bin/env bash
# Authoritative full-suite run for ACT-SWAMP-CHARACTERIZE-REST01.
# Substrate: native arm64 Deno 2.9.7; synthetic HOME; external cache.
set -u
cd /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/swamp
export HOME=/tmp/swamp-char-rest01.ipyvth/home
export DENO_DIR=/tmp/swamp-char-rest01.ipyvth/deno
export TMPDIR=/tmp
export SWAMP_NO_TELEMETRY=1
OUT=.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stdout
ERR=.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stderr
EXIT=.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/exitcode
DURATION=.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/duration.txt
COMMAND=.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/command.txt
START_TXT=.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/start.txt
END_TXT=.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/end.txt
START=$(date +%s)
echo $START > $START_TXT
printf 'HOME=%s\nDENO_DIR=%s\nTMPDIR=%s\nSWAMP_NO_TELEMETRY=%s\nDeno=%s\ncommand=deno task test\nstarted=%s\n' \
  "$HOME" "$DENO_DIR" "$TMPDIR" "$SWAMP_NO_TELEMETRY" \
  "$(/tmp/deno-arm64/deno --version | head -1)" \
  "$START" > $COMMAND
set +e
/tmp/deno-arm64/deno task test >"$OUT" 2>"$ERR"
RC=$?
set -e
END=$(date +%s)
echo $END > $END_TXT
echo $((END-START)) > $DURATION
printf '%s\n' "$RC" > "$EXIT"
echo "done exit=$RC duration=$((END-START))s"
