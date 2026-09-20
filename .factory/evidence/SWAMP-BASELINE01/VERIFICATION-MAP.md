# VERIFICATION-MAP — Swamp at BASELINE01

Per-step characterisation of the three local verification workflows.
This map is structural; runtime reproduction is recorded in `BASELINE.md`.

## Common machinery

### Verdict parser (`scripts/check_review_verdict.ts`)

- **inputs**: review output file + label
- **outputs**: `GATE_VERDICT: pass|fail|missing|provider-error` line, exit 0 or 1
- **deterministic**: yes (pure function `determineVerdict`)
- **may skip**: no — it runs whenever it is invoked
- **skip condition**: not applicable
- **failure behavior**: exit 1 on anything except `pass`
- **recorded evidence**: `GATE_VERDICT:` line in log
- **authority role**: enforces the "missing marker fails" contract documented in `agent-constraints/verification-conventions.md` and `swamp-club#2265`

Marker pattern (line-initial, with markdown-emphasis tolerance):

```
^[ \t*]*VERDICT[ \t*]*:[ \t*](pass|fail)
```

Provider-error pattern (precedes marker check):

```
hit your (weekly|daily|monthly) limit|rate_limit_error|overloaded_error|authentication_error|invalid_api_key|credit balance is too low|exceeded your.*quota
```

Substantive output floor: 50 bytes. Below = `missing` with reason `empty-output`.

### Workflow runner (the swamp binary)

- **workflow / job / step**: every step uses `command/shell` model type. The `command/shell` executor correctly fails on non-zero exit code.
- **guard**: CEL expression against `data.latest('repo-' + run.id, 'diff').attributes.files`. Returns `true` → skip. Returns `false` → run.
- **inputs**: commit + branch (mandated by `inputs.required` on every workflow). Used to find the worktree (commit) and the merge-base diff (branch).
- **setup**: every workflow does `git worktree add --detach "$CHECKOUT_DIR" "${{ inputs.commit }}"` in a fresh `/tmp/swamp-verify-{name}-${run.id}` directory.

## Workflow: `verify-build`

| Step | Command | Deterministic | External | May skip | Failure mode |
| --- | --- | ---: | --- | --- | --- |
| `setup/checkout` | `git worktree add …` | yes | — | no | exit |
| `static-analysis/lint` | `deno lint` | yes | — | no | exit |
| `static-analysis/fmt-check` | `deno fmt --check` | yes | — | no | exit |
| `static-analysis/type-check` | `deno task check` | yes | — | no | exit |
| `tests/run-tests` | `deno task test` | yes (in spirit; parallel races exist) | — | no | exit |
| `deps-audit/vuln-scan` | `deno task audit` | yes (queries `api.osv.dev`) | OSV.dev | no | exit |
| `compile/build` | `deno task compile` | yes | — | no | exit |
| `compile/binary-check` | `./swamp --version` | yes | — | no | exit |
| `cleanup/remove-worktree` | `git worktree remove` | yes | — | always | non-fatal |

`run-tests` in our baseline run: 12 128 passed, 160 failed, 30 ignored.
155/160 failures are environmental (Nix-managed `~/.claude/` is read-only);
5 need classification.

Trust root of this workflow:

- Same Deno that installed it (system's deno is in PATH).
- `git` binary for worktree operations.
- Network for OSV.dev audit.
- Network for Deno JSR/npm cache.
- The actual code being verified (no hashes — relies on git's integrity).

External dependencies that may NOT be configured in this environment:
- none. `verify-build` has no credential requirement.

## Workflow: `verify-reviews`

| Step | Guard | Command | Deterministic | External | May skip |
| --- | --- | --- | --- | ---: | --- |
| `setup/checkout` | — | `git worktree add` + `swamp repo init` | yes | — | no |
| `detect-changes/diff` | — | `@swamp/git diff` (threeWay) | yes (git) | — | no |
| `detect-changes/changed-files` | depends on diff | `@swamp/git diff --nameOnly` | yes (git) | — | no |
| `reviews/code-review` | **none** (always runs) | `claude -p` + `check_review_verdict.ts` | no (LLM-judged) | Claude | no |
| `reviews/adversarial-review` | src/{cli,domain,infrastructure,libswamp,serve,worker}/ | `claude -p` + verdict | no (LLM-judged) | Claude | yes |
| `reviews/ux-review` | src/cli/commands/, src/presentation/, src/domain/errors.ts, src/libswamp/ | `claude -p` + verdict | no (LLM-judged) | Claude | yes |
| `reviews/ci-security-review` | .github/workflows/ | `claude -p` + verdict | no (LLM-judged) | Claude | yes |
| `cleanup/remove-worktree` | — | `git worktree remove` | yes | — | always |

Review invocation details:

- `claude -p - --model claude-{opus,sonnet}-4-6 --allowedTools "Read,Glob,Grep"`
- Allowed tools: `Read, Glob, Grep` only (no Bash, no Edit).
- Output piped to a result file, then `scripts/check_review_verdict.ts` parses it.

Note on review subject correctness (H2):

- The diff is computed via `git diff $(git merge-base origin/main HEAD) > DIFF_FILE` (merge-base-relative, matching the workflow's own `threeWay: true` guard inputs).
- The Claude invocation receives the diff path at end of prompt.
- Model variants: `claude-opus-4-6` for code/adversarial/ci-security, `claude-sonnet-4-6` for UX.

Note on guard semantics (H3):

The adversarial-review guard is:

```yaml
guard: |
  ${{ data.latest('repo-' + run.id, 'diff').attributes.files.filter(
      f, f.startsWith('src/cli/') ||
         f.startsWith('src/domain/') ||
         f.startsWith('src/infrastructure/') ||
         f.startsWith('src/libswamp/') ||
         f.startsWith('src/serve/') ||
         f.startsWith('src/worker/')).size() == 0 }}
```

This guards against **zero matches** (skip when no matches). If a commit
touches ONLY `extensions/`, `scripts/`, `design/`, `verification/`, etc.
without touching the listed `src/` prefixes, the guard is true and the
review is skipped — even if the change affects adversarial surfaces.

The commit message (`bcaa9695`) and its in-attestation reviewer note
explicitly call this out and file it as `swamp-club#2289`. So this is
**CONFIRMED_STRUCTURALLY** by the source.

Trust root:
- `claude` CLI on PATH (no API key required if `~/.claude` is logged in).
- The provided diff (via `git diff $(git merge-base)`).
- Same `deno` binary as the build workflow.
- Same `git` for worktree ops.

External dependencies:
- Claude API (or Claude CLI auth).
- Network to fetch `git merge-base origin/main` (via `git fetch origin main`).

This ACT **did not** run `verify-reviews` end-to-end because neither the
Claude CLI auth nor `ANTHROPIC_API_KEY` is configured here. `claude` was
not on `PATH` either.

## Workflow: `verify-skills`

| Step | Guard | Command | Deterministic | External | May skip | Missing-credential behavior |
| --- | --- | --- | --- | --- | --- | --- |
| `setup/checkout` | — | `git worktree add` + `swamp repo init` | yes | — | no | — |
| `detect-changes/changed-files` | — | `@swamp/git diff --nameOnly` | yes (git) | — | no | — |
| `skills/skill-review` | guard: `.claude/skills/`, `CLAUDE.md`, `scripts/review_skills.ts`, `evals/promptfoo/` | `deno task review-skills` | no (LLM-judged) | Tessl | yes | **FAILS** if `TESSL_TOKEN` missing (per `verification-conventions.md`) |
| `skills/skill-trigger-eval` | (same guard) | `deno task eval-skill-triggers` | no (LLM-judged) | Anthropic API | yes | **SKIPS** gracefully if `ANTHROPIC_API_KEY` missing |
| `cleanup/remove-worktree` | — | `git worktree remove` | yes | — | always | — |

Critical detail: the skill guard fires on `evals/promptfoo/**` too, so
the trigger eval itself is gated by changes to its own config — that's
a self-bootstrap pattern but it means a brand-new skill description
won't trigger the eval unless the eval config changes too. Worth
noting but not a defect.

Trust root:
- Same as verify-reviews, plus Tessl token + Anthropic API key.

This ACT did not run `verify-skills` either.

## Summary of authority roles

The workflows are not "AI verification" as one undifferentiated category.
They have at least four distinct authority roles:

1. **Deterministic native** — `lint`, `fmt`, `check`, `test`, `audit`,
   `compile`, `binary-check`, worktree setup/teardown. Subject = the
   commit. Subject-binding is via git SHA on the worktree path.
2. **Path-guard skeleton** — every review/eval step begins with the
   same pattern: load the diff, build a file list, evaluate a CEL guard
   against that list, skip if zero relevant files. Subject-binding is
   via the merge-base diff.
3. **LLM-judged** — each review step delegates to `claude -p` with a
   review prompt + the diff. The verdict parser enforces fail-closed
   behaviour on missing markers and provider errors.
4. **External-tokens** — Tessl token (required), Anthropic API key
   (required for reviews, optional for trigger eval — but reviews
   still call Claude CLI which itself needs auth).

The chain is: deterministic setup → guard evaluation → LLM invocation
→ verdict parser → workflow-level status. Each step has its own
authority role, and a "skipped" step at the guard stage records as
`skipped (guard)` in the workflow run history. Whether downstream
attestations preserve this distinction is documented in
`VERIFICATION-MAP.md` continuation and `FINDINGS.md`.