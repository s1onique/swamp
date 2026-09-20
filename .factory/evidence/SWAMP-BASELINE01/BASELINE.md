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
| `integration/telemetry_invocation_context_test.ts` | 1 | `JSR package manifest for '@cliffy/command' failed to load` inside child `swamp repo init`; assertion `actual=1 expected=0` at `:112:5`. PermissionDenied is present in stderr but the trigger is JSR-cache. *(environmental — JSR cache)* |
| `integration/telemetry_workflow_method_invocations_test.ts` | 1 | Identical JSR-cache failure for `@cliffy/command`; assertion at `:183:7`. *(environmental — JSR cache)* |
| `src/cli/commands/doctor_audit_test.ts` | 2 | `runChildWithAbort: SIGTERM/SIGKILL` — `Error: expected … child to exit promptly; took 30029ms / 30032ms`. Real subprocess timing assertion at test's own 30s timeout. *(unclassified — genuine_or_flaky)* |
| `src/domain/extensions/extension_quality_checker_test.ts` | 2 | `fmt` / `lint` ANSI escape codes assertion — `assertEquals(true, false)`. Real ANSI detection in subprocess output. *(unclassified — genuine_or_flaky)* |

Total confirmed-environmental: **156 of 160** (154 `mkdir` PermissionDenied + 2 JSR-cache misses). The remaining **4** are unclassified (genuine_or_flaky) and must be re-run individually in `SWAMP-TEST-CHAR01` to distinguish real defects from load-induced flake.

> Note (CORRECTION02): the original BASELINE01 attribution of the two
> telemetry rows to "`swamp repo init` permission" was wrong. Re-reading
> the assertion bodies in the raw `test.stdout` shows the trigger is
> `JSR package manifest for '@cliffy/command' failed to load. Failed
> caching 'https://jsr.io/@cliffy/command/meta.json'` at
> `src/cli/commands/model_method_history_logs.ts:20:25`. The
> PermissionDenied is present in stderr but is not what the assertion
> fires on.

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
