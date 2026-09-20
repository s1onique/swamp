# ACT-SWAMP-BASELINE01-CORRECTION01

**Scope**: only `.factory/**`. No production source mutation.

**Why this exists.** A Factory reviewer identified three internal
inconsistencies in the `SWAMP-BASELINE01` evidence packet:

1. **Arithmetic defect.** The packet claimed `155 environmental + 5
   unclassified = 160`, with a per-file breakdown that did not
   reconcile — the per-file rows added to **156**, and the per-test
   `FAILED` markers numbered 166, not 160.

2. **Epic board defect.** `SWAMP-BASELINE01` was listed as `ACTIVE`
   in `.factory/epic-board.md`, but the ACT was closed at commit
   time.

3. **Patch hygiene defect.** `git diff --check` actually fails on
   the committed range (`.factory/tmp/native-baseline/test.stdout`
   has a blank-line-at-EOF whitespace error, and 4 of 7 generated
   Markdown files lack a trailing newline). The ACT §21 closure
   claim "git diff --check was empty" is therefore false.

These are mechanical bookkeeping defects, not structural findings
about Swamp. The underlying baseline observations are sound; only
the recorded counts, board state, and hygiene claims are wrong.

**Goal.** Reconcile the recorded counts against the raw test
output, fix the board state, fix the patch hygiene, and re-affirm the
negative claims.

---

## 1. Re-derive the canonical failure inventory

The deno test runner prints:

- A per-test progress line of the shape
  `./<path>_test.ts => <name> ... <ok|FAILED> (<duration>)`.
- A ` FAILURES ` block listing each failed test once with
  `=> ./<path>:<line>`.
- A summary line of the shape
  `FAILED | <N> passed | <M> failed | <K> ignored (<S> steps)`.

The naive grep `=> .*FAILED` matches 166 lines, but 6 of them are
false positives — the test names themselves contain the literal
substring `FAILED` (e.g. `FetchOtlpExporter: returns FAILED on HTTP
error responses`). Those tests are listed as `... ok` and pass.

The correct filter is `=> .*FAILED` AND NOT `... ok`:

```bash
grep -aE '=> .*FAILED' .factory/tmp/native-baseline/test.stdout \
  | grep -vE '\.\.\. .*ok'
```

That filter returns exactly **160 lines**, matching the summary.

The `FAILURES` block also returns exactly 160 unique entries, with
this per-file breakdown:

| File | Failures |
| --- | ---: |
| `src/domain/repo/repo_service_test.ts` | 106 |
| `src/cli/repo_context_test.ts` | 32 |
| `integration/webhook_signature_schemes_test.ts` | 6 |
| `integration/scheduled_trigger_inputs_test.ts` | 5 |
| `integration/remote_execution_test.ts` | 5 |
| `src/domain/extensions/extension_quality_checker_test.ts` | 2 |
| `src/cli/commands/doctor_audit_test.ts` | 2 |
| `integration/telemetry_workflow_method_invocations_test.ts` | 1 |
| `integration/telemetry_invocation_context_test.ts` | 1 |
| **Total** | **160** ✓ |

Sum = 160. Arithmetic is now mechanically conserved.

## 2. Re-derive the environmental classification

The original packet attributed 155 of the 160 failures to
`~/.claude/` being read-only (the `RepoService.init` PermissionDenied
chain). Re-traced:

- **Environmental** (154 total — `RepoService.init` PermissionDenied
  reaches into `mkdir ~/.claude/skills/swamp`):
  - `src/domain/repo/repo_service_test.ts`: 106
  - `src/cli/repo_context_test.ts`: 32
  - `integration/webhook_signature_schemes_test.ts`: 6
  - `integration/scheduled_trigger_inputs_test.ts`: 5
  - `integration/remote_execution_test.ts`: 5
- **Unclassified** (6 total — not the originally reported 5):
  - `src/domain/extensions/extension_quality_checker_test.ts`: 2
  - `src/cli/commands/doctor_audit_test.ts`: 2
  - `integration/telemetry_workflow_method_invocations_test.ts`: 1
  - `integration/telemetry_invocation_context_test.ts`: 1

`154 + 6 = 160` ✓

The original packet's `155 + 5 = 160` was arithmetically correct but
*not derivable from the per-file rows* — that mismatch was the
defect. The 5-test `fetch_otlp*` and 1-test `libswamp/data/query`
groupings in the original packet were *phantom* — those tests pass
in this baseline (their names contain the substring `FAILED` so a
naive grep flagged them).

## 3. Fix Factory bookkeeping

- Update `.factory/epic-board.md`: `SWAMP-BASELINE01 | ACTIVE` →
  `SWAMP-BASELINE01 | CLOSED` (and add the correction ACT row).
- Update `.factory/evidence/SWAMP-BASELINE01/RESULT.md`: replace
  "155 environmental / 5 unclassified" with the canonical 154/6
  breakdown.
- Update `.factory/evidence/SWAMP-BASELINE01/FINDINGS.md`: same
  numbers; F3 list reflects the 6 unclassified tests.
- Update `.factory/evidence/SWAMP-BASELINE01/manifest.json`: same
  numbers; the per-file `tests` array under F3 reflects the 6
  unclassified tests in 4 files.
- Update `.factory/evidence/SWAMP-BASELINE01/BASELINE.md`: same.

## 4. Fix patch hygiene

- Trim trailing blank line from
  `.factory/tmp/native-baseline/test.stdout`.
- Add trailing newline to all generated Markdown files that lack
  one (`for f in *.md; do tail -c 1 "$f" | od -An -c | grep -q '\\n' || printf '\n' >> "$f"; done`).
- Re-run `git diff --check` and record the result in this ACT.

## 5. Negative claims (at correction closure)

```
NO_SWAMP_PRODUCTION_CODE_CHANGED=true
NO_UPSTREAM_PR_CREATED=true
NO_UPSTREAM_LIFECYCLE_STATE_WRITTEN=true
NO_ATTESTATION_FORGED=true
NO_SKIPPED_STEP_COUNTED_AS_EXECUTED=true
NO_MODEL_REVIEW_COUNTED_AS_DETERMINISTIC=true
BASELINE_SUBJECT_EXACTLY_IDENTIFIED=true
EVIDENCE_PACKET_MECHANICALLY_CONSISTENT=true   # NEW
```

If `EVIDENCE_PACKET_MECHANICALLY_CONSISTENT` cannot be asserted, the
verdict must be `EVIDENCE_PACKET_INVALID`.

## 6. Exit criteria

The correction closes with one of:

- `EVIDENCE_PACKET_CORRECTED` — mechanical conservation laws hold:
  `environmental + unclassified == total_failed`, per-file sums
  reconcile, board state agrees with ACT state, patch hygiene agrees
  with closure hygiene, manifest agrees with prose.
- `EVIDENCE_PACKET_INVALID` — any of the above conservation laws
  fail after one round of correction. In that case, the
  `SWAMP-BASELINE01` packet is invalidated and `SWAMP-DOGFOOD01` /
  `SWAMP-ATTACK01` must wait for a re-run baseline.

---

# END ACT-SWAMP-BASELINE01-CORRECTION01
