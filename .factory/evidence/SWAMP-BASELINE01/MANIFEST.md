# MANIFEST — SWAMP-BASELINE01

Evidence bundle for ACT SWAMP-BASELINE01. Schema is intentionally simple.

| File | Kind | Subject | Format |
| --- | --- | --- | --- |
| `MANIFEST.md` | index | this file | markdown |
| `BASELINE.md` | environment + toolchain + native checks | BASELINE_SHA | markdown |
| `AUTHORITY-MAP.md` | per-signal authority decomposition | BASELINE_SHA | markdown |
| `ARCHITECTURE-MAP.md` | bounded component map | BASELINE_SHA | markdown |
| `VERIFICATION-MAP.md` | per-step verification workflow map | BASELINE_SHA | markdown |
| `FINDINGS.md` | findings (H1–H4, F1–F11) | BASELINE_SHA | markdown |
| `RESULT.md` | verdict + closures + negative claims | BASELINE_SHA | markdown |

## Raw evidence (under `.factory/tmp/`)

| File | Size | Description |
| --- | ---: | --- |
| `.factory/tmp/native-baseline/check.stdout` | small | `deno check main.ts` stdout |
| `.factory/tmp/native-baseline/check.stderr` | small | `deno check main.ts` stderr (with /usr/bin/time output) |
| `.factory/tmp/native-baseline/check.exitcode` | tiny | exit code + duration |
| `.factory/tmp/native-baseline/lint.stdout` | small | `deno lint` stdout |
| `.factory/tmp/native-baseline/lint.exitcode` | tiny | exit code |
| `.factory/tmp/native-baseline/fmt.stdout` | small | `deno fmt --check` stdout |
| `.factory/tmp/native-baseline/fmt.exitcode` | tiny | exit code |
| `.factory/tmp/native-baseline/test.stdout` | ~17 650 lines | `deno task test` stdout |
| `.factory/tmp/native-baseline/test.stderr` | ~970 lines | `deno task test` stderr |
| `.factory/tmp/native-baseline/test.exitcode` | tiny | exit code |
| `.factory/tmp/native-baseline/compile.stdout` | small | `deno task compile` stdout (downloads deno, compiles) |
| `.factory/tmp/native-baseline/compile.stderr` | small | with /usr/bin/time output |
| `.factory/tmp/native-baseline/compile.exitcode` | tiny | exit code |
| `.factory/tmp/data-experiment.ts` | small | data-layer test invocation harness |
| `.factory/evidence/SWAMP-BASELINE01/deno-version.txt` | tiny | `deno --version` captured output |

## SHA-256 hashes of evidence files

Computed via `shasum -a 256`. See `manifest.json` for the full machine-
readable form.

## Evidence hygiene (codified by CORRECTION02)

Raw evidence artifacts under `.factory/tmp/**` are **immutable**
byte-faithful captures of tool output. They are exempt from
`git diff --check` whitespace hygiene. Normalized or redacted
derivatives must live under `.factory/evidence/**/normalized/**`
if patch hygiene is required.

`git diff --check` is applied **only** to authored artifacts (the
ones under `.factory/evidence/**` and `.factory/acts/**`). The raw
`.factory/tmp/**/test.stdout` is intentionally not in that set.

A normalized derivative of `test.stdout` is provided at
`.factory/evidence/SWAMP-BASELINE01/normalized/test-summary.txt`
for downstream tooling that wants diff-friendly text.

## SHA-256 of immutable raw evidence (verified at CORRECTION02)

| File | SHA-256 |
| --- | --- |
| `.factory/tmp/native-baseline/test.stdout` | `ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417` |

This hash must remain stable across all future Factory ACTs that
build on BASELINE01. Any drift is provenance loss.
