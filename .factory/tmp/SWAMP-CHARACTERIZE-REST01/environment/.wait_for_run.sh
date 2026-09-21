#!/bin/bash
set -u
FUL_PID=$(cat /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/swamp/.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/run.pid | tr -d 'A-Z_=\n')
echo "Waiting for full run PID=$FUL_PID"
for i in $(seq 1 600); do
  if ! kill -0 $FUL_PID 2>/dev/null; then
    echo "Done after ${i}s"
    exit 0
  fi
  if [ -f /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/swamp/.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/exitcode ]; then
    echo "exitcode exists after ${i}s"
    exit 0
  fi
  sleep 5
done
echo "TIMEOUT after 3000s — run still active"
exit 1
