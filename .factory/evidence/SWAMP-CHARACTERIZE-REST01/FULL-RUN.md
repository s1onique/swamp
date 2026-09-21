# Full-run record — ACT-SWAMP-CHARACTERIZE-REST01

## Required fields

| field | value |
| ----- | ----- |
| subject | `a392c49e1c899fbbbbf39bf84d73a8308c048eb6` |
| command | `deno task test` (resolves to `SWAMP_NO_TELEMETRY=1 deno test --parallel --unstable-bundle --allow-read --allow-write --allow-env --allow-run --allow-net --allow-sys --allow-ffi`) |
| deno binary | `/tmp/deno-arm64/deno` (Deno 2.9.7 stable, aarch64-apple-darwin) |
| kernel / OS | Darwin 23.6.0 arm64 |
| HOME | `/tmp/swamp-char-rest01.ipyvth/home` (synthetic writable) |
| DENO_DIR | `/tmp/swamp-char-rest01.ipyvth/deno` (external cache, prewarmed) |
| TMPDIR | `/tmp` |
| DENO_JOBS | default (CPU-count workers) |
| started (epoch) | 1790007678 |
| ended (epoch) | 1790008306 |
| duration_seconds | 628 (≈10m 28s) |
| runner summary line | `FAILED | 12287 passed (214 steps) | 33 failed | 30 ignored (1 step) (10m11s)` |
| runner passed | 12287 |
| runner failed | 33 |
| runner ignored | 30 |
| runner total | 12350 (= 12287 + 33 + 30) |
| exit code | 1 |
| natural completion | **TRUE** |
| harness termination | none — Deno emitted final summary naturally |
| external tool timeout | none |

**NATURAL_COMPLETION=true.**

## Why this run is authoritative

- Deno emitted a final FAILED summary line.
- Exit code captured immediately after process exit (delayed-`$?`
  bug explicitly avoided — capture happens in the same shell command
  that ran `deno task test`, before any other shell mutation).
- No external SIGTERM/SIGKILL interrupted the run (the detached
  nohup wrapper was never invoked to terminate the run).
- No tool-timeout responsible — the run completed on its own
  ~10m28s after start.

## Files

- `full/stdout` (3.2 MB) — Deno test runner output, ANSI decorations
  preserved byte-faithful.
- `full/stderr` (60 KB) — Deno Check phase output + a single
  `Error: Connection reset` line that did not affect any test
  outcome.
- `full/exitcode` — `1`.
- `full/duration.txt` — `628`.
- `full/start.txt`, `full/end.txt` — start/end epoch seconds.
- `full/command.txt` — captured command, env-vars, Deno version.
- `full/parser.json` — Deno test result parser output
  (`.factory/scripts/parse_deno_test_result.ts` on stdout+stderr).
- `full/classified-inventory.json` — failures grouped into clusters
  with classification + evidence strength.
