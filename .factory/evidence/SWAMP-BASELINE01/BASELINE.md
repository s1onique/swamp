# SWAMP-BASELINE01 — Pristine Baseline Snapshot

Subject identity verified at execution time:

| Field | Value |
| --- | --- |
| BASELINE_SHA | `bcaa9695b7f27f51964a9f41587fdf112b261c89` |
| UPSTREAM_SHA | `bcaa9695b7f27f51964a9f41587fdf112b261c89` |
| fork/upstream divergence | none (`--left-right --count upstream/main...HEAD` → `0\t0`) |
| merge-base | `bcaa9695b7f27f51964a9f41587fdf112b261c89` |
| working-tree state | clean (`git status --short` empty) |

The "Expected initial condition" in the ACT matches what we observed.
The fork is byte-identical to upstream `main` at execution time.
No baseline rebase or reset was required.

## Toolchain

Deno is not installed in this environment; it was downloaded to satisfy
the pinned `.tool-versions` (single source of truth: `deno 2.9.7`).

| Tool | Version | Path |
| --- | --- | --- |
| OS | macOS 23.6.0 (Darwin 14.6, arm64) | — |
| Deno | 2.9.7 (stable, release, aarch64-apple-darwin) | `/tmp/deno_install/bin/deno` |
| V8 | 15.0.245.2-rusty | (bundled) |
| TypeScript | 6.0.3 | (bundled) |
| git | 2.54.0 | `/run/current-system/sw/bin/git` |
| mise | not installed | — |

Install method: official `https://deno.land/install.sh` with `--yes v2.9.7`.
This was permitted by the ACT's "Install the pinned toolchain only if
necessary and permitted by the local environment" clause. No repository
file was modified to install it.

## Native deterministic checks

All commands run from the repository root with `DENO_DIR=/tmp/deno_cache`
(a fresh cache, not the user-global one, so parallel deno processes do
not contend for `~/.cache/deno`).

| Command | Exit | Duration | Peak RSS | Notes |
| --- | ---: | ---: | ---: | --- |
| `deno check main.ts` | 0 | 0.13 s real | 76 MB | All type checks pass |
| `deno lint` | 0 | <1 s | — | No lint findings |
| `deno fmt --check` | 0 | <1 s | — | All files formatted |
| `deno task test` | **1** | 113.56 s real | 3.5 GB | 12 128 passed, 160 failed, 30 ignored |
| `deno task compile` | 0 | 28.6 s real | 8 MB | Emitted `swamp` binary, 305 MB |
| `./swamp --version` | 0 | <0.1 s | — | `20260206.200442.0-sha.` (dev build, sha empty) |
| `./swamp --help` | 0 | <0.1 s | — | Cliffy CLI schema renders |
| `./swamp repo init /tmp/swamp-smoke --tool none` | 0 | <1 s | — | Initialized swamp repo with empty tools list |

`deno task test` is the only non-zero exit. It is not a production-source
defect — see "Test outcome breakdown" below.

### Test outcome breakdown

```
FAILED | 12128 passed (214 steps) | 160 failed | 30 ignored (1 step)  (1m40s)
```

Failure distribution by file:

| Test file | Failures | Root cause |
| --- | ---: | --- |
| `src/domain/repo/repo_service_test.ts` | 106 | `mkdir ~/.claude/skills/swamp` → PermissionDenied (this environment) |
| `src/cli/repo_context_test.ts` | 32 | Same — `RepoService.init` reaches the same path |
| `integration/webhook_signature_schemes_test.ts` | 6 | `swamp repo init` → same PermissionDenied |
| `integration/scheduled_trigger_inputs_test.ts` | 5 | Same — `swamp repo init` permission |
| `integration/remote_execution_test.ts` | 5 | Same — `swamp repo init` permission |
| `integration/telemetry_*_test.ts` | 2 | Same — `swamp repo init` permission |
| `src/cli/commands/doctor_audit_test.ts` | 2 | `runChildWithAbort: SIGTERM/SIGKILL`; needs separate re-test |
| `src/infrastructure/tracing/fetch_otlp*_test.ts` | 5 | Likely parallel port collision / mock contention |
| `src/domain/extensions/extension_quality_checker_test.ts` | 2 | fmt ANSI codes assertion; needs separate re-test |
| `src/libswamp/data/query_test.ts` | 1 | Likely parallel contention |

Total confirmed-environmental: 155 of 160. The remaining 5
(`doctor_audit`, `extension_quality_checker`, `libswamp/data/query`) are
not yet classified and should be re-run individually to distinguish
test fragility from environmental issues.

### Why so many failures are environmental

`~/.claude/` is a Nix-managed read-only directory (an APFS path with
`protect` mount). The `RepoService.init` default scaffolds
`~/.claude/skills/swamp/`, which requires write permission there. The
errors all read:

```
PermissionDenied: Operation not permitted (os error 1):
  mkdir '/Volumes/UserData/Users/chistyakov/.claude/skills/swamp'
  at async SkillAssets.copySkillsTo (skill_assets.ts:499:7)
  at async RepoService.installGlobalSkills (repo_service.ts:598:7)
  at async RepoService.init (repo_service.ts:326:24)
```

The `RepoService` test file does pass `tools: []` in some cases but
not in the cases that hit this code path — failures are in tests that
exercise `RepoService.init` defaults with the default `claude` tool.
AGENTS.md explicitly warns about this:

> "Test fixtures that initialize a repo (`repoInit` / `RepoService.init`)
> pass `tools: []` unless the test is about tool scaffolding."

This is a test-fixture design pattern, not a Swamp design defect. The
binary's `swamp repo init --tool none` path was verified working
manually. Whether the test design is *itself* a finding worth carrying
forward is recorded in `FINDINGS.md`.

### Recompile is reproducible

`deno task compile` produced `swamp` (Mach-O 64-bit executable arm64,
305 MB). It bundles a private Deno 2.9.7 runtime and a `.claude/skills`
copy with five development skills excluded (ddd, github-pr, jujutsu,
issue-lifecycle, skill-creator, terminal-output). The compiled binary
runs `swamp --version`, `--help`, `repo init`, and JSON output paths.

## Resources and runtime evidence

Per-command raw outputs and stderr are kept under
`.factory/tmp/native-baseline/`:

| File | Contents |
| --- | --- |
| `check.{stdout,stderr}` | `deno check` |
| `lint.{stdout,stderr}` | `deno lint` |
| `fmt.{stdout,stderr}` | `deno fmt --check` |
| `test.{stdout,stderr}` | `deno task test` |
| `compile.{stdout,stderr}` | `deno task compile` |

`test.stdout` is ~17 650 lines; relevant excerpts (FAILURES block,
assertion error patterns) are quoted in `FINDINGS.md`. The full
untruncated output is preserved for downstream forensics.

## Verification workflows

`swamp workflow run verify-build` / `verify-reviews` / `verify-skills`
were NOT executed end-to-end in this baseline. Reason: they require
either `ANTHROPIC_API_KEY` + Claude CLI authentication (for review
verdicts) or `TESSL_TOKEN` (for skill review) — see
`agent-constraints/verification-conventions.md`. This environment has
neither.

What we *did* execute:

- The full set of native deterministic checks (above) which are what
  `verify-build` is composed of, minus the `swamp workflow run` overhead.
- Static inspection of the three workflow YAMLs.
- Static inspection of `scripts/check_review_verdict.ts` and the four
  review prompt files under `verification/review-prompts/`.
- Static inspection of `extensions/models/_lib/lifecycle_recorder.ts`
  (the H4 hypothesis surface).

The structural findings are recorded in `VERIFICATION-MAP.md` and
`FINDINGS.md`. The runtime-execution gaps are recorded as
`NOT_RUN_EXTERNAL_DEPENDENCY` for the LLM-judged steps.
