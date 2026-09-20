# RESULT — SWAMP-BASELINE01

```
ACT: SWAMP-BASELINE01
verdict: BASELINE_ESTABLISHED_WITH_GAPS
BASELINE_SHA: bcaa9695b7f27f51964a9f41587fdf112b261c89
UPSTREAM_SHA: bcaa9695b7f27f51964a9f41587fdf112b261c89
fork/upstream divergence: none (0/0 commits, merge-base = HEAD)
```

## Toolchain versions

```
OS: Darwin 23.6.0 (arm64) on /Volumes/UserData (apfs, protect)
Deno: 2.9.7 (stable, release, aarch64-apple-darwin) — installed via official installer to /tmp/deno_install/bin/deno
V8: 15.0.245.2-rusty (bundled)
TypeScript: 6.0.3 (bundled)
git: 2.54.0 (/run/current-system/sw/bin/git)
mise: not installed
swamp: built locally from BASELINE_SHA via deno task compile
  binary: ./swamp (Mach-O 64-bit, 305 MB, includes embedded Deno 2.9.7 + .claude/skills subset)
  version: 20260206.200442.0-sha. (dev build, sha stamp empty per scripts/compile.ts default)
```

## Native deterministic checks

| Command | Exit | Summary |
| --- | ---: | --- |
| `deno check main.ts` | 0 | All type checks pass. |
| `deno lint` | 0 | No lint findings. |
| `deno fmt --check` | 0 | All files formatted. |
| `deno task test` | **1** | 12 128 passed / 160 failed / 30 ignored. 155/160 failures are environmental (Nix-managed read-only `~/.claude/`). 5 need classification. |
| `deno task compile` | 0 | Emitted `swamp` binary (305 MB, Mach-O arm64). |
| `./swamp --version` | 0 | Returns `20260206.200442.0-sha.`. |
| `./swamp --help` | 0 | Renders CLI schema. |
| `./swamp repo init /tmp/swamp-smoke --tool none` | 0 | Initialized swamp repo with empty tool list. |
| `./swamp --no-telemetry --no-color --json model list` | 1 | Fails: `~/.swamp/deno/` extraction → PermissionDenied (Nix-managed `~/.swamp/` is read-only). |
| Data layer test isolation (`data_test.ts` + `data_record_mapper_test.ts` + `data_writer_test.ts`) | 0 | 179 passed / 0 failed. |
| Data layer property tests (`data_property_test.ts`) | 0 | 11 passed / 0 failed. |

## Verification workflows

| Workflow | Run ID | Status | Skipped | Failed | External |
| --- | --- | --- | --- | --- | --- |
| `verify-build` | n/a | NOT_RUN — exercised components directly | n/a | n/a | none |
| `verify-reviews` | n/a | NOT_RUN_EXTERNAL_DEPENDENCY (no Claude CLI auth, no `ANTHROPIC_API_KEY`) | n/a | n/a | Claude API |
| `verify-skills` | n/a | NOT_RUN_EXTERNAL_DEPENDENCY (no `TESSL_TOKEN`, no `ANTHROPIC_API_KEY`) | n/a | n/a | Tessl, Anthropic |

## Attestation reconstruction

Reconstruction possible from a *future* run only. We did not produce an
attestation in this baseline because the workflows were not executed.
Static analysis of `verification/workflow-verify-build.yaml` and the
attestation report (`src/domain/reports/builtin/verification_attestation_report.ts`)
is sufficient to map the structure of what an attestation would carry,
but not its runtime values.

The independent reconstruction the ACT asks for requires a credentials-
bearing environment. Carry into `SWAMP-DOGFOOD01`.

## Known false-PASS surfaces

Count: 1 confirmed, 1 likely, several worth carrying into next ACT.

| Finding | Surface | Status |
| --- | --- | --- |
| F3 (H3) | Adversarial-review guard excludes `extensions/` | CONFIRMED_STRUCTURALLY; not yet reproduced at runtime. |
| F7 (inferred) | Empty diff → review trivially passes | INFERRED; needs guard-bug experiment to reproduce. |
| F2 | Workflow overall success co-exists with skipped reviews | CONFIRMED_STRUCTURALLY; structurally mitigated by per-step status in attestation report. |

## Known false-FAIL surfaces

Count: 1 environmental pattern, 5 unclassified individual failures.

| Finding | Surface | Status |
| --- | --- | --- |
| F1 | Nix-managed `~/.claude/` is read-only → `RepoService.init` fails | OBSERVED_RUNTIME; 155/160 failures. |
| F3 | 5 unclassified test failures (`doctor_audit`, `fetch_otlp*`, `extension_quality_checker`, `libswamp/data/query`) | OBSERVED_RUNTIME; not classified. |

## Authority map

**Status**: completed. See `AUTHORITY-MAP.md`.

## Architecture map

**Status**: completed. See `ARCHITECTURE-MAP.md`.

## Data / versioning experiment

**Status**: partial — see `FINDINGS.md` F9.

```
property: path traversal is always rejected ............................ ok
property: single dots in names are accepted ............................ ok
property: version is always positive .................................. ok
property: tags always include 'type' .................................. ok
property: isOwnedBy is reflexive and ignores provenance fields ........ ok
property: isOwnedBy rejects a different ref or type ................... ok
property: serialization round-trips every metadata field .............. ok
property: round-tripped data exposes the same accessors ............... ok
property: zero-duration lifetimes normalize to 'workflow' ............. ok
property: new version preserves identity .............................. ok
property: deletion markers tombstone without changing identity ........ ok
```

11/11 data property tests passed. Plus 179 data-layer tests across
`data_test.ts`, `data_record_mapper_test.ts`, `data_writer_test.ts`.

Label: `OBSERVED_IMMUTABILITY_BEHAVIOR` (per the ACT's specified
caution — we did not assert a stronger invariant without
implementation analysis).

End-to-end data flow (CLI `swamp model method run`) is BLOCKED in
this environment because the compiled binary cannot extract its
embedded Deno runtime to `~/.swamp/deno/` (F10).

## Working-tree state

```
$ git status --short
(empty — no tracked changes)
$ git diff --stat
(empty — no diff)
$ git diff --check
(empty — no diff)
```

`./swamp` (compiled binary) is gitignored per `.gitignore`. Other
untracked paths:

```
.factory/   (the Factory evidence this ACT produced)
.swamp/     (gitignored runtime data — leftover from test runs)
swamp       (gitignored compiled binary)
deno_cache  (only if at root — it isn't; it's at /tmp/deno_cache)
```

## Commit state

```
$ git rev-parse HEAD
bcaa9695b7f27f51964a9f41587fdf112b261c89
$ git rev-parse upstream/main
bcaa9695b7f27f51964a9f41587fdf112b261c89
$ git merge-base HEAD upstream/main
bcaa9695b7f27f51964a9f41587fdf112b261c89
```

## Negative claims

```
NO_SWAMP_PRODUCTION_CODE_CHANGED=true
NO_UPSTREAM_PR_CREATED=true
NO_UPSTREAM_LIFECYCLE_STATE_WRITTEN=true
NO_ATTESTATION_FORGED=true
NO_SKIPPED_STEP_COUNTED_AS_EXECUTED=true
NO_MODEL_REVIEW_COUNTED_AS_DETERMINISTIC=true
BASELINE_SUBJECT_EXACTLY_IDENTIFIED=true
```

All negative claims are true. The only tracked files this ACT will
produce are under `.factory/**`.

## Recommended next ACT

`SWAMP-DOGFOOD01` is the next ACT in the epic board, but the evidence
collected here suggests the highest-value next ACT is to **isolate and
characterise the test-suite fragility** (F1/F3) by running `deno task
test` in a writable-`~/.claude/` environment. The discrepancy between
this baseline's 12 128 passes and the upstream PR's claimed 12 288
passes must be explained before any "dogfood" experiment can be
trusted. Therefore:

Recommended: a *pre*-`SWAMP-DOGFOOD01` ACT focused on the test suite,
classifying the 5 unclassified failures and confirming the 155
environmental ones are reproducible from a clean environment.

If the operator prefers to follow the pre-existing epic board
literally, then `SWAMP-DOGFOOD01` is the choice — but with the
caveat that the dogfood results will be tainted by the unknown
state of the test suite until F1/F3 are resolved.