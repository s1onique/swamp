# ACT-SWAMP-BASELINE01

**Mission.** Establish the first independently reproducible Factory
baseline of Swamp in `https://github.com/s1onique/swamp`.

This repository is a convenience fork of `https://github.com/swamp-club/swamp`.

At ACT authorization time, both fork and upstream `main` resolve to
`bcaa9695b7f27f51964a9f41587fdf112b261c89`. Confirmed at execution time.

**Purpose**: observation, reproduction, qualification, and authority mapping.

**Not** an improvement ACT. Do not repair, refactor, redesign, or
"clean up" anything discovered. The output of this ACT is a
trustworthy baseline from which later Swamp-mining ACTs can proceed.

---

## 0. Core doctrine

Treat the repository as a specimen. The distinction this ACT enforces:

```text
what documentation says
        ≠
what source appears to imply
        ≠
what execution actually demonstrates
```

All three may be recorded. Only the third may be promoted to
**observed runtime evidence**.

Likewise:

```text
model/reviewer assertion
        ≠
deterministic verification
```

Do not collapse them into one PASS signal. The agent may interpret
evidence; the agent must not manufacture authoritative evidence.

---

## 1. Primary questions (12)

Q1  Does pristine Swamp build from the pinned toolchain?
Q2  Does pristine Swamp's deterministic test/check suite pass?
Q3  Can Swamp's own documented verification workflows run successfully in this environment?
Q4  Which verification steps are: deterministic / model-judged / external-service-dependent / guarded-skippable / advisory / blocking?
Q5  What exact subject does each verification result bind to?
Q6  What runtime/evidence state does Swamp persist?
Q7  Can a verification step silently skip while an overall workflow still succeeds?
Q8  What configuration, prompts, scripts, models, or external state form the verification trust root?
Q9  Can an attestation be reconstructed independently from recorded workflow execution data?
Q10 Which claims cannot be established in this environment, and why?
Q11 What known or newly discovered fail-open / false-PASS surfaces exist?
Q12 What mechanisms are most relevant for later extraction into Factory / ClineMM / Cline bot / Mrvn?

Do **not** attempt to solve Q11 findings in this ACT.

Answers are in `RESULT.md` and `FINDINGS.md`.

---

## 2. Scope

**Allowed tracked modifications**: only `.factory/`. No production source.

**Allowed untracked/runtime**: `.swamp/`, worktrees, logs, compiled
artifacts, Deno caches, verification workflow runtime state. Commit
small bounded excerpts only.

**Forbidden**: `src/**`, `extensions/**`, `verification/**`, `scripts/**`,
`evals/**`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `deno.json`,
`.tool-versions`, `Dockerfile`, existing tests/workflows/prompts —
unless an unavoidable environment-only correction is required.

If a forbidden change appears necessary:

```text
STOP mutation
record BLOCKED_BY_ENVIRONMENT
describe the required change
continue whatever read-only qualification remains possible
```

---

## 3. Provenance gate

```
git remote -v
git rev-parse HEAD
git branch --show-current
git status --short
git log -1 --format=fuller
```

If `upstream` is absent: `git remote add upstream https://github.com/swamp-club/swamp.git`,
then `git fetch upstream main`.

Record:

```
git rev-parse HEAD
git rev-parse upstream/main
git merge-base HEAD upstream/main
git rev-list --left-right --count upstream/main...HEAD
```

Define:

```text
BASELINE_SHA=<actual HEAD>
UPSTREAM_SHA=<actual fetched upstream/main>
```

If they differ, do not reset or rebase. Record divergence and continue
against `BASELINE_SHA`.

Observed at execution time:

| Field | Value |
| --- | --- |
| `BASELINE_SHA` | `bcaa9695b7f27f51964a9f41587fdf112b261c89` |
| `UPSTREAM_SHA` | `bcaa9695b7f27f51964a9f41587fdf112b261c89` |
| `merge-base` | `bcaa9695b7f27f51964a9f41587fdf112b261c89` |
| divergence | `0\t0` (zero on each side) |

---

## 4. Bootstrap Factory specimen metadata

Created:
- `.factory/acts/SWAMP-BASELINE01.md` (this file)
- `.factory/epic-board.md` (with the 10 ACTs from §4 of the ACT)

---

## 5. Inventory before execution

Mapped at minimum: `README.md`, `AGENTS.md`, `CLAUDE.md`, `deno.json`,
`.tool-versions`, `agent-constraints/`, `verification/`, `scripts/`,
`evals/`, `src/domain/`, `src/infrastructure/`, `src/worker/`,
`src/serve/`, `extensions/`.

Identified: CLI entrypoint, model abstraction, definition abstraction,
workflow abstraction, data abstraction, vault abstraction, CEL
machinery, workflow scheduler, run persistence, datastore abstraction,
report/attestation machinery, worker/remote-execution machinery,
skills, skill evaluation, verification workflows, review-verdict
machinery.

See `ARCHITECTURE-MAP.md`.

---

## 6. Toolchain qualification

| Tool | Version | Notes |
| --- | --- | --- |
| OS | Darwin 23.6.0 (arm64) | mounted with `protect` on `/Volumes/UserData` |
| Deno | 2.9.7 | installed via `https://deno.land/install.sh --yes v2.9.7` to `/tmp/deno_install/bin/deno` |
| V8 | 15.0.245.2-rusty | bundled |
| TypeScript | 6.0.3 | bundled |
| git | 2.54.0 | `/run/current-system/sw/bin/git` |
| mise | not installed | — |

Pinned version in `.tool-versions` (`deno 2.9.7`) was not changed.

---

## 7. Deterministic native baseline

`deno check main.ts` → exit 0, 0.13 s real, 76 MB peak RSS.
`deno lint` → exit 0.
`deno fmt --check` → exit 0.
`deno task test` → exit 1, 113.56 s real, 3.5 GB peak RSS, **12 128 passed / 160 failed / 30 ignored**.
`deno task compile` → exit 0, 28.6 s real, emitted `swamp` binary (305 MB, Mach-O arm64).

Resource observation recorded where available (wall time, peak RSS,
output volume). No threshold applied.

---

## 8. Built binary smoke qualification

`./swamp --version` → `20260206.200442.0-sha.` (exit 0).
`./swamp --help` → renders CLI schema (exit 0).
`./swamp --no-telemetry --no-color repo init /tmp/swamp-smoke --tool none` → exit 0.
`./swamp --no-telemetry --no-color --json model list` → exit 1, BLOCKED_BY_ENVIRONMENT
  (`Failed to load extension models: Operation not permitted (os error 1):
   mkdir '/Volumes/UserData/Users/chistyakov/.swamp/deno'`).

---

## 9. Swamp native verification inventory

See `VERIFICATION-MAP.md`. Per-step characterisation of all three
workflows, including the verdict parser (`scripts/check_review_verdict.ts`),
the four review prompts, and the four authority roles
(deterministic native / path-guard skeleton / LLM-judged / external-tokens).

---

## 10. Verification execution

| Workflow | Status | Reason |
| --- | --- | --- |
| `verify-build` | NOT_RUN — components exercised directly | n/a |
| `verify-reviews` | NOT_RUN_EXTERNAL_DEPENDENCY | no Claude CLI auth, no `ANTHROPIC_API_KEY` |
| `verify-skills` | NOT_RUN_EXTERNAL_DEPENDENCY | no `TESSL_TOKEN`, no `ANTHROPIC_API_KEY` |

No secrets printed; presence/absence recorded.

---

## 11. Retrieve actual workflow history

No workflow runs to retrieve. Workflows were not executed (see §10).

---

## 12. Independent attestation reconstruction

**Not possible in this baseline** because the workflows were not
executed. Static analysis of structure recorded in
`VERIFICATION-MAP.md` and `FINDINGS.md`.

Trust-root SHA-256 hashes recorded in `manifest.json`:

- `scripts/check_review_verdict.ts`
- `scripts/review_skills.ts`
- `verification/workflow-verify-build.yaml`
- `verification/workflow-verify-reviews.yaml`
- `verification/workflow-verify-skills.yaml`
- `verification/review-prompts/{code,adversarial,ux,ci-security}-review.md`
- `CLAUDE.md`, `AGENTS.md`

No `swamp-club` POST made. No upstream PR opened.

---

## 13. Skip semantics experiment

Static analysis only — see F2 / F7 in `FINDINGS.md`. No production
mutation performed. The workflow's per-step status does distinguish
`skipped (guard)` from `succeeded`; the attestation report
(`src/domain/reports/builtin/verification_attestation_report.ts`)
renders `○` for skipped steps (verified by
`verification_attestation_report_test.ts`, passing).

---

## 14. Hypotheses

- **H1 (missing verdict fails closed)**: CONFIRMED_STRUCTURALLY in
  `scripts/check_review_verdict.ts`. Marker is line-initial with
  markdown-emphasis tolerance; provider errors outrank a marker.
  Runtime reproduction NOT_TESTED (no Claude CLI).
- **H2 (merge-base diff for reviews)**: CONFIRMED_STRUCTURALLY.
  Shell scripts re-derive `git diff $(git merge-base origin/main HEAD)`
  independently of the guard's `data.latest(...).attributes.files`.
- **H3 (adversarial guard excludes extensions/)**: CONFIRMED_STRUCTURALLY.
  Filed as swamp-club#2289 by the upstream PR author.
- **H4 (lifecycle recorder raises on failure)**: CONFIRMED_STRUCTURALLY
  in `extensions/models/_lib/lifecycle_recorder.ts`. Two pinned
  assertions prevent erosion.

---

## 15. Authority map

See `AUTHORITY-MAP.md`. Every verification signal decomposed into
its authority role. Factory classifications are descriptive, not
rollout authority.

---

## 16. Data / evidence model characterisation

Label: **`OBSERVED_IMMUTABILITY_BEHAVIOR`** (per the ACT's specified
caution).

11/11 property tests at `src/domain/data/data_property_test.ts` passed.
Plus 179 data-layer tests across `data_test.ts`,
`data_record_mapper_test.ts`, `data_writer_test.ts`. End-to-end CLI
data flow BLOCKED in this environment (F10).

---

## 17. Failure-injection prohibition

No production mutation. No guard changes. No verdict parser changes.
No data implementation changes. H3 is identified but not exploited.

---

## 18. Findings taxonomy

See `FINDINGS.md`. Every finding carries one evidence label and one
impact class.

---

## 19. Extraction candidates

See `FINDINGS.md` F11. 19 mechanisms tabulated across Factory,
ClineMM, Cline bot, Mrvn. Recommendations are provisional
(`ADOPT_CANDIDATE`, `ADAPT_CANDIDATE`, `NEEDS_DOGFOOD`).

---

## 20. Result states

**Verdict: `BASELINE_ESTABLISHED_WITH_GAPS`**.

Native deterministic baseline ran. Important native verification
behaviour was executed/characterised. Evidence provenance is sound.
Unresolved gaps (verification workflows not run end-to-end, ~155
environmental test failures, 5 unclassified test failures, CLI
binary blocked on `~/.swamp/deno/` extraction) do not prevent
meaningful continuation.

---

## 21. Closure evidence

See `RESULT.md`.

Working tree before commit:
```
$ git status --short   # empty (modulo .factory/ additions)
$ git diff --check     # empty
$ git diff --stat      # empty (modulo .factory/ additions)
```

---

## 22. Commit discipline

Only `.factory/**` will be committed. Message:

```text
factory(swamp): establish upstream baseline
```

Body:
```text
Factory-ACT: SWAMP-BASELINE01
Factory-State: CLOSED
Factory-Verdict: BASELINE_ESTABLISHED_WITH_GAPS
Factory-Subject: bcaa9695b7f27f51964a9f41587fdf112b261c89
Factory-Upstream: bcaa9695b7f27f51964a9f41587fdf112b261c89
```

No upstream commit amended. New commit in `s1onique/swamp`. Not
pushed to `swamp-club/swamp`. No upstream PR opened.

---

## 23. Negative claims (at closure)

```
NO_SWAMP_PRODUCTION_CODE_CHANGED=true
NO_UPSTREAM_PR_CREATED=true
NO_UPSTREAM_LIFECYCLE_STATE_WRITTEN=true
NO_ATTESTATION_FORGED=true
NO_SKIPPED_STEP_COUNTED_AS_EXECUTED=true
NO_MODEL_REVIEW_COUNTED_AS_DETERMINISTIC=true
BASELINE_SUBJECT_EXACTLY_IDENTIFIED=true
```

---

## 24. Stop conditions

No stop condition triggered.

---

## 25. What NOT to do next

The ACT will not auto-launch `SWAMP-DOGFOOD01`, `SWAMP-ATTACK01`,
`SW-F01`, `SW-F02`, `SW-CM01`, `SW-X01`, or `SW-M01`. The baseline
packet is returned to the operator.

---

# END ACT-SWAMP-BASELINE01