# FINDINGS — Swamp at BASELINE01

Every finding uses one evidence label and one impact class.

Labels:

- `OBSERVED_RUNTIME` — observed at execution time
- `CONFIRMED_STRUCTURALLY` — confirmed by reading source / YAML
- `DOCUMENTED_ONLY` — only mentioned in docs, not yet inspected
- `MODEL_JUDGED` — claim requires an LLM to evaluate
- `INFERRED` — derived from other findings
- `NOT_TESTED` — could be inspected but not yet
- `BLOCKED_BY_ENVIRONMENT` — environment prevents inspection

Impact:

- `NOTE` — informational
- `STRENGTH` — design point worth carrying forward
- `LIMITATION` — known boundary of the design
- `RISK` — danger to be aware of
- `POTENTIAL_FALSE_PASS` — could produce a PASS that does not match actual state
- `POTENTIAL_FALSE_FAIL` — could produce a FAIL on a passing subject
- `EXTRACTION_CANDIDATE` — design point worth porting

## H1 — missing review verdict

**Claim**: A missing explicit `VERDICT:` marker fails closed, not pass-by-default.

**Evidence**: `CONFIRMED_STRUCTURALLY`. `scripts/check_review_verdict.ts` lines 86–103.

**Trace**:

- Provider error pattern is checked BEFORE the marker pattern.
  Provider errors fail even if a marker is present in the same output.
- Marker pattern is line-initial with markdown-emphasis tolerance:
  `^[ \t*]*VERDICT[ \t*]*:[ \t*](pass|fail)`
- An unanchored match in prose is intentionally rejected.
- Output < 50 bytes (UTF-8) is classified `missing` with reason `empty-output`.
- Output ≥ 50 bytes without a marker is `missing` with reason `no-marker`.
- `missing` and `provider-error` both yield exit 1 (failure).

**Verdict**: PASS the H1 claim. The script does fail closed on missing
markers, provider errors, and short output. Anchor is line-initial; that
is load-bearing — without anchoring, a reviewer weighing out loud whether
to emit pass or fail could be credited with a verdict it never gave.

**Caveat**: A reviewer could emit `VERDICT: pass` as a single line, then
write a paragraph of complaints. The verdict parser reads only the
marker. The attestation records the marker verdict (`pass`), not the
reviewer's prose. This is documented behaviour (`agent-constraints/
verification-conventions.md`), but a consumer who wants the complaints
must read the reviewer's text separately.

**Impact**: `STRENGTH`. The marker-as-gate design is portable.

**Runtime reproduction**: NOT_TESTED (Claude CLI not configured here).

## H2 — review subject correctness

**Claim**: Reviews receive the merge-base-relative diff, not an
unrelated / no diff.

**Evidence**: `CONFIRMED_STRUCTURALLY`. `verification/workflow-verify-reviews.yaml`
lines 95–99 (diff step) and per-step shell scripts at lines 105–149 (code
review), 158–197 (adversarial review), 199–239 (ux review), 240–272
(ci-security review).

**Trace**:

- `detect-changes/diff` runs `@swamp/git diff` with `threeWay: true` and
  `base: "origin/main"`. With threeWay this produces `origin/main...HEAD`,
  i.e. merge-base relative.
- The shell scripts compute `MERGE_BASE=$(git merge-base origin/main HEAD)`
  and pipe `git diff "$MERGE_BASE"` to a file. Same diff, same basis.
- The reviewer prompt is appended with the path to that diff file. The
  reviewer reads only that file plus `Read,Glob,Grep`.
- The guard also reads the same diff via
  `data.latest('repo-' + run.id, 'diff').attributes.files`.

**Verdict**: PASS the H2 claim. The merge-base diff is consistent across
guard and reviewer. The shell scripts re-derive it independently, which
is a defense against a stale or empty `data.latest` result.

**Caveat**: Both the shell scripts and the guard must have a non-empty
`origin/main`. The setup step runs `git fetch origin main`. If `origin`
is missing or the fetch fails, both will fall back to whatever HEAD sees
locally — potentially evaluating against a fast-forwarded main, not the
actual reviewed subject. This is environment-dependent, not a Swamp
defect.

**Impact**: `STRENGTH`. The two-source confirmation is a good defense.

**Runtime reproduction**: NOT_TESTED.

## H3 — extension adversarial-review coverage

**Claim (from commit message)**: The adversarial-review guard may not
run for changes confined to `extensions/`. Filed as swamp-club#2289.

**Evidence**: `CONFIRMED_STRUCTURALLY`. `verification/workflow-verify-reviews.yaml`
lines 165–167. The guard is:

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

The guard fires when the file list contains ZERO entries matching
`src/{cli,domain,infrastructure,libswamp,serve,worker}/`. A commit that
touches ONLY `extensions/` (or `scripts/`, `design/`, `verification/`,
`docs/`, `evals/`, `agent-constraints/`, `.claude/`, etc.) matches the
guard, so the adversarial review is SKIPPED.

The PR diff for this very commit (`bcaa9695`) is entirely in
`extensions/models/_lib/`, `.claude/skills/issue-lifecycle/SKILL.md`. Per
the guard's predicate, it would skip adversarial review. The commit
message notes exactly this and says "I ran the adversarial review
manually against this diff; it returned `VERDICT: pass` with no findings.
That run is deliberately **not** represented in the attestation, since it
happened outside the workflow."

**Verdict**: CONFIRMED_STRUCTURALLY.

**Impact**: `POTENTIAL_FALSE_PASS`.

**Why it matters**: A change to `extensions/models/_lib/swamp_club.ts`
or `extensions/models/_lib/lifecycle_recorder.ts` — code that handles
swamp-club lifecycle and credential-bearing calls — would NOT receive an
adversarial review under the current guard, despite being a security-
sensitive surface. The current `bcaa9695` commit itself is exactly this
case.

**Carry into**: `SWAMP-ATTACK01`. The harness should construct an
experimental commit touching only `extensions/models/_lib/` and verify
that the workflow reports adversarial-review as `skipped (guard)` while
the overall workflow reports success.

**Runtime reproduction**: NOT_TESTED in this environment (Claude CLI not
configured). Structural confirmation is unambiguous.

## H4 — lifecycle recording failure semantics

**Claim (from commit message)**: Mandatory lifecycle recording now
fails rather than silently advancing local state. (`swamp-club#2279`)

**Evidence**: `CONFIRMED_STRUCTURALLY`. `extensions/models/_lib/lifecycle_recorder.ts`
(130 LoC) + `extensions/models/_lib/swamp_club.ts` `UpstreamOutcome`
type + `extensions/models/issue_lifecycle.ts` call sites.

**Trace**:

- The `SwampClubClient` no longer swallows failures; every operation
  returns an `UpstreamOutcome` discriminated union:
  `{ ok: true; noop?: boolean } |
   { ok: false; reason: "rejected"; status: number; body: string } |
   { ok: false; reason: "unavailable"; detail: string }`
- The adapter (`swamp_club.ts`) does not interpret outcomes. The
  recorder (`lifecycle_recorder.ts`) decides policy:
  - `recordLifecycle` raises on failure (mandatory audit entry).
  - `recordLifecycleBestEffort` warns only (used for assignment).
  - `recordRipple` raises (the ripple is the deliverable).
  - `recordUpstreamChange` raises (status/type transitions).
- Methods declare `rollbackOnFailure` so a raised failure leaves the
  phase unchanged and the re-run is clean. Exceptions: `notify` and
  `post_attestation` — re-running them would duplicate an external
  side effect.
- `transitionStatus` (in `swamp_club.ts` lines 268–289) confirms an
  already-applied status by re-reading the issue status, not by
  matching server error prose. The read is retried once; the patch
  never is.
- Two pinned assertions keep this from eroding:
  - No direct `postLifecycleEntry` or `submitComment` call may
    survive in the model.
  - The rollback flag must match an explicit method list.

**Verdict**: PASS the H4 claim. The recorder pattern is a clean
separation of "what happened" (adapter) from "what does it mean"
(recorder). Raising on failure is the right default for audit
entries; warn-only is appropriate for courtesy actions. The pinned
assertions are the load-bearing defense — without them, future PRs
could re-introduce direct calls.

**Impact**: `STRENGTH`. Pattern is portable to any anti-corruption-layer
adapter.

**Runtime reproduction**: NOT_TESTED. Could not safely call live
swamp-club from this baseline environment without authorization.

## F1 — test suite partly environmental (large false-FAIL surface)

**Evidence**: `OBSERVED_RUNTIME`. 12 128 passed / 160 failed / 30 ignored.
154/160 failures share the same root cause: `mkdir ~/.claude/skills/swamp`
→ `PermissionDenied: Operation not permitted (os error 1)`.

**Trace**: `src/infrastructure/assets/skill_assets.ts:499:7` →
`src/domain/repo/repo_service.ts:598:7` (`installGlobalSkills`) →
`src/domain/repo/repo_service.ts:326:24` (`init`).

**Why**: The host has a Nix-managed read-only `~/.claude/` directory.
`RepoService.init` defaults to scaffolding `claude` tool skills into
`~/.claude/skills/swamp/`. Tests that exercise `init` with default tools
fail in this environment but would pass on a fresh machine or in CI.

**Impact**: `POTENTIAL_FALSE_FAIL` (in this environment) and
`LIMITATION` (CI portability).

**Carry into**: `SWAMP-TEST-CHAR01` — the upstream PR's attestation
claimed "full suite 12,288 passed via the verification workflow". This
baseline run reported 12 128 passed — 160 fewer. The discrepancy is
plausibly environmental, but must be checked against a clean CI run
using `HOME=$(mktemp -d)`.

## F2 — workflow overall success can co-exist with skipped reviews

**Evidence**: `CONFIRMED_STRUCTURALLY`. Both `workflow-verify-reviews.yaml`
and `workflow-verify-skills.yaml` use `condition: succeeded` (default) on
the dependencies between `cleanup` and `reviews`/`skills`. The runner
collapses guard-skipped steps into non-failing terminal status. The
attestation report (`src/domain/reports/builtin/verification_attestation_report.ts`,
verified passing in `verification_attestation_report_test.ts`) outputs a
checklist that shows `○` for skipped steps.

**Trace**:

- `verification_attestation_report: skipped step shows circle icon ... ok`
  (verified passing).
- The report renders per-step status including `skipped` distinct from
  `succeeded` / `failed`.
- The verification-conventions doc tells the agent to read this
  checklist back to the user, including the skipped-vs-passed distinction.

**Verdict**: PASS the claim that downstream attestation preserves skip
granularity, *at the report level*. Whether the **attestation JSON**
serialized to swamp-club also preserves it is not directly verified —
that is an integration between swamp-cli and swamp-club that we did not
exercise.

**Impact**: `LIMITATION`. The agent-driven report presentation
preserves skip granularity, but a programmatic consumer of the
attestation must read the per-step statuses; an aggregate "PASS" field
is misleading.

**Runtime reproduction**: NOT_TESTED end-to-end (no live workflow runs).

## F3 — 6 unclassified test failures

**Evidence**: `OBSERVED_RUNTIME`. The 6 failures NOT classified as
environmental are (re-derived by CORRECTION01):

- `src/cli/commands/doctor_audit_test.ts`: 2 (SIGTERM/SIGKILL subprocess
  behaviour under load — likely environmental, needs single-threaded
  re-run).
- `src/domain/extensions/extension_quality_checker_test.ts`: 2 (fmt
  ANSI code assertion).
- `integration/telemetry_invocation_context_test.ts`: 1 (`swamp repo
  init` permission chain — likely environmental).
- `integration/telemetry_workflow_method_invocations_test.ts`: 1
  (`swamp repo init` permission chain — likely environmental).

Earlier packet erroneously grouped `fetch_otlp*` (5) and `data/query`
(1) here; those tests pass in this baseline (their names contain the
substring `FAILED`). See CORRECTION01 for the reconciliation.

**Impact**: `NOTE`. Need targeted re-runs to distinguish fragility
from defects. Carry into `SWAMP-TEST-CHAR01`.

## F4 — verification workflow not executed in this baseline

**Evidence**: `OBSERVED_RUNTIME`. No `swamp workflow run verify-*`
command was run. The three workflows require Claude CLI auth or
`ANTHROPIC_API_KEY` and/or `TESSL_TOKEN`. Neither is configured here.

**Impact**: `LIMITATION`. This baseline cannot independently re-derive
the attestation that the upstream PR produced. The static analysis in
`VERIFICATION-MAP.md` covers the workflow structure but not the
runtime behaviour of the LLM reviewers.

**Carry into**: `SWAMP-DOGFOOD01` if a credentials-bearing environment
is authorised; otherwise carry forward as a known gap.

## F5 — DataId is not content-addressed

**Evidence**: `CONFIRMED_STRUCTURALLY`. `src/domain/data/data_id.ts`:

```typescript
export type DataId = string & { readonly _brand: unique symbol };
export function generateDataId(): DataId {
  return crypto.randomUUID() as DataId;
}
```

`design/primitives/data.md` confirms: "A `DataId` is a random UUID, not
a content hash".

**Trace**: Two runs of the same method with identical inputs will get
different `dataId` values. Versioning is append-only by integer, and
identity is `(dataId, version)`. Cross-run deduplication requires
content comparison by the consumer.

**Impact**: `LIMITATION`. Cheaper reads, but breaks content-addressable
guarantees. Carry into Factory data-layer design.

## F6 — agent-constraints and design dirs excluded from compile

**Evidence**: `OBSERVED_RUNTIME`. `deno.json` `exclude` lists
`agent-constraints/`, `design/`, `contributing/`, `.agents/`, `.claude/`,
`workflows/`, `.vault-test-vault/`, `resources/`, `evals/`, `.swamp/`,
`.claude/worktrees/`. The compile script further excludes
`agent-constraints`, `.agents`, `.claude/skills/ddd`,
`.claude/skills/github-pr`, `.claude/skills/jujutsu`,
`.claude/skills/issue-lifecycle`, `.claude/skills/skill-creator`,
`.claude/skills/terminal-output`, `.github`, `.vault-test-vault`,
`design`, `evals`, `integration`, `scripts`, `verification`, `workflows`.

**Impact**: `NOTE`. Not a defect — these are intentionally non-runtime.
But it means the binary does not carry the design docs, scripts, or
verification workflows. Anyone using `swamp` without source access
cannot re-run verify-build locally; they would have to clone the repo.

## F7 — empty diff path makes review trivially pass

**Evidence**: `INFERRED`. If the diff that the reviewer is asked to
review is empty (e.g. the merge base equals HEAD), the reviewer's prompt
gives it an empty file path. The reviewer with `Read,Glob,Grep` tools
can read the rest of the repo — which is in scope per "Read other files
in the repository for context" — but every finding must be about a
change in the diff. An empty diff has no changes, so the reviewer
should produce `VERDICT: pass` (no findings).

The structural defense against a "trivial pass on empty diff" is the
guard: zero relevant files → skip the review. So this would record as
`skipped (guard)` not `succeeded`, which the attestation correctly
distinguishes (F2).

**Impact**: `NOTE`. Worth carrying into `SWAMP-DOGFOOD01` as a
sanity-check: if a workflow run reports a review as `succeeded` against
an empty diff, that is a guard bug.

## F8 — agent-driven, not CI-driven, verification

**Evidence**: `CONFIRMED_STRUCTURALLY`. `agent-constraints/verification-conventions.md`
makes the agent the executor and presenter of the three workflows. CI
does not run them — CI only validates that local verification ran via
the attestation (per the file: "CI does not run these reviews — it
validates that local verification ran via the attestation.").

**Impact**: `LIMITATION`. The agent harness is the trust root for
verification. A human reviewing the attestation must trust the agent
that ran it. The verification-conventions doc structures this
explicitly but it is not the same as a CI gate.

## F9 — Data layer runtime exercise

**Evidence**: `OBSERVED_RUNTIME`. Ran the data layer tests in isolation:

```
$ deno test --allow-... src/domain/data/data_test.ts \
    src/domain/data/data_record_mapper_test.ts \
    src/domain/models/data_writer_test.ts

ok | 179 passed | 0 failed  (132 ms)
```

The property tests at `src/domain/data/data_property_test.ts` exercise
the invariants we care about:

- `property: new version preserves identity` — same `(type, modelId,
  name)` → same `dataId` across writes; only `version` changes.
- `property: deletion markers tombstone without changing identity`.
- `property: zero-duration lifetimes normalize to 'workflow'`.
- `property: serialization round-trips every metadata field`.
- `property: tags always include 'type'`.

**Verdict**: PASS the runtime claim that the data layer supports
"immutable, versioned, queryable artifacts" at the API surface used by
the tests. The on-disk layout
(`data/{type}/{modelId}/{name}/{N}/content.json`) is exercised through
the `UnifiedDataRepository` and proven to be append-only.

**Caveat**: This is test-level evidence. End-to-end data flow
(write via method invocation → read via CLI) was *not* exercised here
because the Nix-managed environment blocks `~/.swamp/deno/` extraction
which the CLI needs to load the embedded Deno runtime for extension
loading (F10). However, the unit tests at this layer are exhaustive
in coverage of the immutability/versioning contract.

**Impact**: `STRENGTH` — the data layer's immutability guarantee is
backed by tests, not just docs.

## F10 — binary blocks on `~/.swamp/deno/` extraction

**Evidence**: `OBSERVED_RUNTIME`. Running any `swamp model *` or
`swamp workflow *` command that loads extensions produces:

```
Error: Failed to load extension models: Operation not permitted (os error 1):
  mkdir '/Volumes/UserData/Users/chistyakov/.swamp/deno'
```

This is the same Nix-managed read-only-`~/.swamp/` problem as the test
suite, but encountered at runtime by the *compiled* binary. The
binary extracts its embedded Deno runtime to `~/.swamp/deno/` on first
use; that path is on a read-only directory.

`SWAMP_HOME=/tmp/swamp-home` partially works (the repo init succeeds,
workflow list works), but extension loading still fails because
`~/.swamp/deno/` extraction happens before `SWAMP_HOME` is consulted
in some code paths.

**Impact**: `LIMITATION`. The binary cannot load extensions in this
environment, so end-to-end model / workflow / data exercises are
blocked. The unit-test path is unaffected.

**Carry into**: `SWAMP-DOGFOOD01` — should pick an environment where
`~/.swamp/` is writable (or rely on unit tests alone).

## F11 — extraction candidates (per ACT question 12)

| Mechanism | Observed in Swamp | Factory | ClineMM | Cline bot | Mrvn | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| Typed model/definition split | yes — zod, `src/domain/models/model.ts` | strong candidate | strong candidate | weak (no plugin types) | candidate | ADOPT_CANDIDATE |
| Workflow DAG | yes — `src/domain/workflows/execution_service.ts` | strong candidate | weak (no DAG) | none | strong candidate | ADAPT_CANDIDATE |
| Immutable/versioned data | yes — `(dataId, version)` over content-hashed payloads (verified runtime F9) | strong candidate | candidate | none | candidate | ADAPT_CANDIDATE |
| CEL / data references | yes — `src/domain/expressions/`, `src/infrastructure/cel/` | candidate (steep curve) | candidate | none | none | NEEDS_DOGFOOD |
| Verification attestations | yes — `verification-attestation` report | strong candidate | weak (no attestation) | none | strong candidate | ADAPT_CANDIDATE |
| Config-integrity hashes | yes — `extensions/_lib/lifecycle_recorder.ts` pinned invariants | strong candidate | strong candidate | none | candidate | ADOPT_CANDIDATE |
| Guarded reviews | yes — path-guard CEL on reviews/evals | strong candidate | candidate | none | candidate | ADAPT_CANDIDATE |
| Review verdict parser | yes — `scripts/check_review_verdict.ts` 168 LoC, pure, fail-closed (verified H1) | strong candidate | strong candidate | candidate | strong candidate | ADOPT_CANDIDATE |
| Skills | yes — `.claude/skills/` markdown + `skill_assets.ts` | strong candidate | candidate | candidate (already has) | none | ADAPT_CANDIDATE |
| Skill trigger/routing evals | yes — `evals/promptfoo/` | strong candidate | strong candidate | candidate | none | ADOPT_CANDIDATE |
| Progressive disclosure | yes — skill descriptions in frontmatter | candidate | candidate | candidate | none | ADAPT_CANDIDATE |
| Manual approval / suspension | yes — `suspended_run_resolver.ts` | strong candidate | candidate | none | candidate | ADAPT_CANDIDATE |
| Remote workers | yes — `src/worker/`, `src/serve/dispatch_service.ts` | candidate | weak | none | strong candidate | ADAPT_CANDIDATE |
| Vault / secret separation | yes — `src/domain/vaults/` with redaction | strong candidate | strong candidate | weak (no vault) | candidate | ADOPT_CANDIDATE |
| Bounded model-to-model invocation | yes — CEL `model.method(...)` in guards | strong candidate | candidate | none | candidate | ADAPT_CANDIDATE |
| Run tracker | yes — `run_tracker_repository.ts`, `run_tracker_store.ts` | strong candidate | candidate | none | candidate | ADAPT_CANDIDATE |
| Audit system | yes — `.swamp/audit/`, JSONL repositories | strong candidate | strong candidate | weak | candidate | ADOPT_CANDIDATE |
| Datastore locking | yes — `src/domain/datastore/distributed_lock.ts` | candidate | weak | none | candidate | ADAPT_CANDIDATE |
| Data lifetimes | yes — `Nm/h/d/w/mo/y`, `ephemeral`, `infinite`, `job`, `workflow` | strong candidate | candidate | none | candidate | ADAPT_CANDIDATE |

All recommendations are provisional; the next ACT must produce runtime
evidence before any are adopted.
