# RED — ACT-SWAMP-ANSI-OUTPUT01

## Recorded SHA at ACT start
- ACT_START_HEAD: d21b7d240b4dbcccd1b5d0db43a6c9343de765ba
- UPSTREAM_HEAD: bcaa9695b7f27f51964a9f41587fdf112b261c89
- BASELINE_SUBJECT: bcaa9695b7f27f51964a9f41587fdf112b261c89
- BASELINE01_RAW_SHA: bcaa9695b7f27f51964a9f41587fdf112b261c89 (preserved; this ACT does not modify any BASELINE01 evidence).

## Recorded production diff vs upstream at ACT start

```
src/cli/commands/doctor_audit.ts         |  270 +-
src/cli/commands/doctor_audit_test.ts    |  601 +-
```

Only the accepted doctor-signal repair diverges from `bcaa9695b7f27f51964a9f41587fdf112b261c89`,
as expected per ACT §3.

## Environment

```
Deno: deno 2.9.7 (stable, release, x86_64-apple-darwin)
v8:   15.0.245.2-rusty
typescript: 6.0.3
Arch: arm64 (system), x86_64 (deno binary under Rosetta)
OS:   Darwin MacBook-Pro-3.local 23.6.0 ... arm64
HOME=/Volumes/UserData/Users/chistyakov
TMPDIR=/private/var/folders/0g/.../T/clinemm-sandbox-temp-ZlNR7z (overridden to /tmp per harness)
DENO_DIR=/tmp/swamp-char01/B2-deno (populated by prior ACTs)
```

## RED capture — full focused test file

Run:
```
deno test --no-check=remote --allow-read --allow-write --allow-env \
          --allow-run --allow-net --allow-sys --allow-ffi \
          src/domain/extensions/extension_quality_checker_test.ts
```

Exit code: **1**

Summary (parsed from cleaned runner output):
```
FAILED | 47 passed | 2 failed (6s)
```

Failing test names (verbatim, ANSI stripped):
```
checkExtensionQuality: fmt output contains no ANSI escape codes
checkExtensionQuality: lint output contains no ANSI escape codes
```

Failure signature (parsed from captured stdout):
```
checkExtensionQuality: fmt output contains no ANSI escape codes =>
  ./src/domain/extensions/extension_quality_checker_test.ts:334:6
error: AssertionError: Values are not equal.
   [Diff] Actual / Expected
  -   true
  +   false
  throw new AssertionError(message);
        ^ at assertEquals (...equals.ts:67:9)
  at extension_quality_checker_test.ts:343:7
```

Raw captured: `.factory/tmp/SWAMP-ANSI-OUTPUT01/red/red.stdout`
(`red.stdout.orig` is a byte-identical backup from the same capture.)

ESC byte presence in red stdout: **491 ESC bytes** (Deno's runner decorates its
own output with ANSI, so this number includes both the broken `QualityIssue.output`
strings AND the runner's own decoration. The relevant signal is the test exit code
+ summary).

## RED capture — dependency behaviour (independent experiment)

Run: `NO_COLOR=1 TERM=dumb` + piped stdout/stderr + x86_64 deno binary.

```
deno fmt --check --no-config model.ts   (unformatted source)
  exit: 1
  stderr bytes: 342
  stderr ESC count: 5  <-- dependency emitted decoration despite NO_COLOR=1
  stdout ESC count: 0
  captured: deno-control/fmt-raw.stderr

deno lint --no-config model.ts          (ban-unused-ignore failure)
  exit: 1
  stderr bytes: 458
  stderr ESC count: 6  <-- dependency emitted decoration despite NO_COLOR=1
  stdout ESC count: 0
  captured: deno-control/lint-raw3.stderr
```

Raw captured bytes (cat -v form) preserved verbatim in
`.factory/tmp/SWAMP-ANSI-OUTPUT01/deno-control/`.

## RED NOT REPRODUCED check

`RED_NOT_REPRODUCED` was NOT triggered. The original RED reproduces cleanly on
Deno 2.9.7 in this environment with the same exit-code / summary signature
that prior characterization established.

## Required RED outcome

```
fmt ANSI test = FAIL   ✓
lint ANSI test = FAIL  ✓
```

Both required RED signals reproduced. Real-dependency RED is in evidence;
no synthetic-contract fallback was needed.
