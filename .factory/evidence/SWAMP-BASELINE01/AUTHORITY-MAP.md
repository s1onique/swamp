# AUTHORITY-MAP — Swamp at BASELINE01

This map decomposes each "verification signal" into its authority role.
The columns are descriptive — they do not assign rollout authority.

Column keys:

| Column | Meaning |
| --- | --- |
| Producer | what generates the signal |
| Deterministic | can be reproduced bit-for-bit |
| LLM | involves a model |
| Can skip | allowed to skip and still report success |
| Subject-bound | tied to the exact commit/diff being verified |
| Blocking | treated as gating by Swamp |
| Evidence retained | recorded in workflow history / log |
| Factory classification | descriptive category |

## The signals

| Signal | Producer | Deterministic | LLM | Can skip | Subject-bound | Blocking | Evidence retained | Factory classification |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `deno check` | Deno | yes | no | no | yes (full source tree) | yes | exit + duration | DETERMINISTIC_CHECK |
| `deno lint` | Deno | yes | no | no | yes | yes | exit code | DETERMINISTIC_CHECK |
| `deno fmt --check` | Deno | yes | no | no | yes | yes | exit code | DETERMINISTIC_CHECK |
| `deno task test` | Deno test runner | yes (in spirit; parallel races) | no | no | yes | yes | step count, duration, per-test outcome | DETERMINISTIC_CHECK |
| `deno task audit` | `scripts/audit_deps.ts` → api.osv.dev | yes (network round-trip) | no | no | yes | yes | OSV.dev result | DETERMINISTIC_CHECK |
| `deno task compile` | Deno compile | yes | no | no | yes | yes | binary on disk | DETERMINISTIC_CHECK |
| `./swamp --version` | compiled binary | yes | no | no | yes | yes | stdout | DETERMINISTIC_CHECK |
| code review | `claude -p` + verdict | no | yes (Claude Opus) | no | yes (merge-base diff) | yes | `GATE_VERDICT:` line | MODEL_ADVISORY |
| adversarial review | same | no | yes (Claude Opus) | yes (path guard) | yes | yes | `GATE_VERDICT:` line | MODEL_ADVISORY |
| UX review | same | no | yes (Claude Sonnet) | yes (path guard) | yes | yes | `GATE_VERDICT:` line | MODEL_ADVISORY |
| CI security review | same | no | yes (Claude Opus) | yes (path guard) | yes | yes | `GATE_VERDICT:` line | MODEL_ADVISORY |
| skill review | `deno task review-skills` → Tessl | no | yes (Tessl) | yes (path guard) | yes | yes | Tessl output | EXTERNAL_JUDGE |
| skill trigger eval | `deno task eval-skill-triggers` → promptfoo + Anthropic API | no | yes (Claude via promptfoo) | yes (path guard) | yes | yes | promptfoo result | EXTERNAL_JUDGE |
| workflow overall status | Swamp's workflow runner | yes (computes from steps) | no | n/a | yes | yes | run history JSON | AGGREGATED_PROJECTION |
| verification attestation | the `verification-attestation` report against the run | yes (computes) | no | n/a | yes | yes | report JSON + markdown | AGGREGATED_PROJECTION |
| config-integrity check | pinned invariants in `extensions/_lib/lifecycle_recorder.ts` | yes | no | no | yes | yes | pinned in repo | DETERMINISTIC_CHECK |
| `claude -p` review invocation | `claude` CLI | no (depends on model) | yes | per-step | yes (diff path in prompt) | yes (via verdict) | reviewer text + `GATE_VERDICT:` | MODEL_ADVISORY |
| `swamp repo init` in workflow setup | swamp binary | yes | no | no | yes (worktree path) | yes (workflow setup fails whole workflow) | stdout/stderr | DETERMINISTIC_CHECK |

## Authority role categories

Swamp does not advertise a vocabulary for this; the Factory categories
below are descriptive, not normative.

### OBSERVATION

A signal that reports state without imposing a gate. Examples:
- Workflow step duration in history.
- Per-test "ok" / "FAILED" line (informational; verdict is the
  authoritative success/fail).
- Telemetry events.

### DETERMINISTIC_CHECK

A signal whose outcome is a pure function of the subject plus the
runtime. Examples: `deno check`, `deno lint`, `deno fmt --check`,
`deno task audit`, `deno task compile`, `./swamp --version`, the
`postLifecycleEntry` pinned invariant.

These can be relied on by downstream attestation machinery — bit-for-bit
reproducibility is possible in principle.

### MODEL_ADVISORY

A signal that depends on the model's behaviour. Examples: the four
code reviews (`claude -p` + `scripts/check_review_verdict.ts`).

Subject-binding is achieved by routing the diff through the prompt;
content-binding is via the verdict marker. The marker is the load-bearing
defense — without it, a model could say anything and the gate would
read the wrong verdict (this is what the swamp-club#2265 fix prevented).

### EXTERNAL_JUDGE

A signal that depends on a third-party service other than the
author's own model. Examples: Tessl, promptfoo eval harness.

These are also LLM-judged but their trust root is the third party,
not the operator's own model.

### QUALIFICATION_SIGNAL

A signal that does not gate the workflow but is recorded as
qualitative evidence. Examples: per-test durations, telemetry
spool, the `RunTracker` records. Not currently used for gating but
retained for forensics.

### AGGREGATED_PROJECTION

A signal derived from many underlying signals. Examples: the
workflow overall status (computed from per-step statuses), the
verification attestation report (computed from the run).

These are interesting because they can be made to look PASSING
while individual signals are SKIPPED or FAILED. Whether the
projection preserves the granularity is a key question for the
attestation.

## Specific notes

- **Code review is the only review without a path guard.** It always
  runs. The other three (adversarial / ux / ci-security) skip when
  no relevant files changed.

- **Skill review has a different missing-credential behavior than
  the reviews.** `verify-conventions.md` says: `TESSL_TOKEN` missing
  → `skill-review` **fails** (exit 1); `ANTHROPIC_API_KEY` missing →
  `skill-trigger-eval` **skips** (exit 0). This asymmetry means a
  workflow run can report overall success with a *mandatory* external
  credential absent, if the guard skipped the step.

- **The workflow overall status is computed by the swamp runner, not
  by an external judge.** The runner collapses "skipped (guard)" into
  a non-failing terminal state at the step level. The attestation
  report then aggregates step statuses — but the verification-
  conventions doc says the attestation is **rebuilt** from the
  workflow history, not copied from the runner's own projection. This
  is the structural defense against silent skip-aggregation.

- **Subject-binding of reviews is via the merge-base diff** (H2
  trace). The diff is created on the host in the worker's `cwd`
  (which is the worktree, because the step sets `workingDir`). The
  guard reads the same diff via `data.latest('repo-' + run.id,
  'diff').attributes.files`. The reviewer prompt explicitly says
  "the diff to review is at <path>" and the reviewer reads only that
  file plus `Read,Glob,Grep`.

- **Subject-binding of the `swamp repo init` step in setup is via
  the worktree path.** The setup step writes a managed section to
  `CLAUDE.md` and `.gitignore`, then immediately `git checkout -- .`
  restores them so the diff between commit and main is unchanged.
