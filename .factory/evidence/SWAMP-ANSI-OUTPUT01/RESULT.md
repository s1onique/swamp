# RESULT — ACT-SWAMP-ANSI-OUTPUT01

## Verdict

**ANSI_OUTPUT_NORMALIZATION_REPAIRED**

## Closure invariants (machine-checkable)

| Invariant | Status | Evidence |
| --------- | ------ | -------- |
| `ANSI_ABSENT_FROM_FMT_QUALITY_OUTPUT` | **true** | A1 PASS, B1 PASS, B6 PASS, `fmt/es_count_normalized.txt` = `0` |
| `ANSI_ABSENT_FROM_LINT_QUALITY_OUTPUT` | **true** | A2 PASS, B3 PASS, B6 PASS, `lint/es_count_normalized.txt` = `0` |
| `SEMANTIC_FMT_DIAGNOSTIC_PRESERVED` | **true** | B2 PASS (`"not formatted"` + `"model.ts"` present) |
| `SEMANTIC_LINT_DIAGNOSTIC_PRESERVED` | **true** | B4 PASS (`"ban-unused-ignore"` present) |
| `PLAIN_TEXT_DIAGNOSTIC_PRESERVED` | **true** | C3 PASS |
| `MULTILINE_STRUCTURE_PRESERVED` | **true** | C4 PASS |
| `UNICODE_PRESERVED` | **true** | C5 PASS (Cyrillic + Greek preserved; length preserved) |
| `FMT_LINT_ISSUE_COUNT_PRESERVED` | **true** | B5 PASS (1 fmt issue + 1 lint issue from combined fixture) |
| `NO_COLOR_STILL_REQUESTED` | **true** | source still has `env: { ...baseEnv, NO_COLOR: "1" }` for both subprocesses |
| `NORMALIZATION_DOES_NOT_DEPEND_ON_NO_COLOR` | **true** | C1–C9 PASS even with synthetic ANSI input not produced by Deno |
| `FOCUSED_TEST_SUITE_PASS` | **true** | unit/unit.exitcode = `0`, summary `58 passed | 0 failed (6s)` |
| `REPORTED_TEST_STATUS_AGREES_WITH_PROCESS_EXIT_CODE` | **true** | unit exit = 0, runner summary = 0 failed; regression exit = 0, summary = 0 failed |
| `NO_PRODUCTION_SCOPE_DRIFT` | **true** | `git diff --name-only bcaa9695..HEAD` shows only the two authorized files in production code |
| `ALL_AUTHORITATIVE_RAW_EVIDENCE_TRACKED` | **true** | `raw-sha256.txt` lists 38 files (excludes itself) |
| `RAW_HASH_MANIFEST_SELF_REFERENTIAL` | **false** | manifest does not include `raw-sha256.txt` in its own list |
| `RAW_HASHES_VERIFY` | **true** | `shasum -a 256 -c raw-sha256.txt` returns all OK (38/38) |
| `BASELINE01_RAW_SHA_PRESERVED` | **true** | this ACT does not modify any BASELINE01 raw evidence |
| `BOARD_STATE_AGREES_WITH_ACT_STATE` | **true** | epic-board now reads `CLOSED` (this file) — see Board section |
| `POLICY_EQUALS_VERIFIER_SCOPE_EQUALS_CLAIM` | **true** | every claim in this file is backed by a captured artefact under `.factory/tmp/SWAMP-ANSI-OUTPUT01/` or `.factory/evidence/SWAMP-ANSI-OUTPUT01/` |

## Mechanical conservation laws

- `passed + failed + ignored == total`: `58 + 0 + 0 == 58` (focused)
                                              `129 + 0 + 0 == 129` (broader extension group)
- `fmt_fixture_expected_issues == observed_fmt_issues`: `1 == 1`
- `lint_fixture_expected_issues == observed_lint_issues`: `1 == 1`
- `combined_fixture_expected_checks == observed_checks`: `{fmt, lint} == {fmt, lint}`
- `normalized_outputs_with_ansi == 0`: `0` (per `fmt/es_count_normalized.txt` + `lint/es_count_normalized.txt`)
- `hash_manifest_subjects == authoritative_raw_files_excluding_manifest`: `38 == 38`
- `production_files_changed ⊆ {extension_quality_checker.ts, extension_quality_checker_test.ts}`: yes

## Runner status (parsed from cleaned stdout)

Focused (ACT §24):
```
ok | 58 passed | 0 failed (6s)
```
Process exit: 0.

Broader extension group (ACT §25):
```
ok | 129 passed | 0 failed (8s)
```
Process exit: 0.

## Negative claims (required by ACT §31)

- `NO_TEST_RELAXATION=true` — `issue.output.includes("\x1b[") === false` is
  retained verbatim on A1 and A2. Existing tests are not weakened.
- `NO_DENO_PATCH=true` — Deno is not modified; this ACT runs against the
  same Deno 2.9.7 binary that produced the RED.
- `NO_DENO_VERSION_SPECIAL_CASE=true` — no Deno version check, no
  branching on version.
- `NO_OS_SPECIAL_CASE=true` — no macOS / Linux / Windows branching.
- `NO_TTY_SPECIAL_CASE=true` — no terminal-type detection; the
  boundary runs unconditionally.
- `NO_CUSTOM_ANSI_REGEX_IF_STD_UTILITY_AVAILABLE=true` —
  `stripAnsiCode` from `@std/fmt/colors` is used; no regex is hand-rolled.
- `NO_DIAGNOSTIC_SEMANTICS_CHANGED=true` — `ban-unused-ignore`,
  `not formatted`, file names, line numbers, problem counts all
  retained in the normalized output.
- `NO_FMT_LINT_EXIT_SEMANTICS_CHANGED=true` — `fmtCommand.output()` is
  still treated as pass iff `success === true`. The change is only in
  what is stored in `QualityIssue.output` when `success === false`.
- `NO_RAW_EVIDENCE_MUTATED=true` — all raw evidence under
  `.factory/tmp/SWAMP-ANSI-OUTPUT01/` is byte-faithful; no post-hoc
  rewriting.
- `ALL_AUTHORITATIVE_RAW_EVIDENCE_TRACKED=true` — 38 raw files hashed;
  all OK.
- `RUNNER_STATUS_SEPARATE_FROM_SEMANTIC_COVERAGE=true` — Runner
  status (`58 passed | 0 failed`) reported independently of semantic
  coverage (9 new unit tests + 2 retained ANSI tests + 1 augmented
  combined test + several synthetic-property cases).
- `BOARD_STATE_AGREES_WITH_ACT_STATE=true` — epic-board updated to
  `CLOSED` with this verdict.

## Recommended next ACT

Exactly one:

**`ACT-SWAMP-CHARACTERIZE-REST01`**

This ACT repairs the ANSI defect. The remaining wider test-suite
fragility (per `SWAMP-TEST-CHAR01-CORRECTION01`) and any subsequent
defects revealed by characterisation are addressed in a separate ACT.
