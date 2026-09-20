# RESULT — SWAMP-BASELINE01-CORRECTION01

**Verdict: `EVIDENCE_PACKET_CORRECTED`**.

## What was fixed

| Defect | Before | After |
| --- | --- | --- |
| Arithmetic | `155 environmental + 5 unclassified = 160` (with phantom fetch_otlp/data/query rows) | `154 environmental + 6 unclassified = 160` (sum reconciles, no phantom rows) |
| Epic board state | `SWAMP-BASELINE01 \| ACTIVE` | `SWAMP-BASELINE01 \| CLOSED` |
| `git diff --check` | FAILED on committed range (blank-line-at-EOF + missing trailing newlines) | passes (after EOF trimming and trailing-newline fix) |

## Canonical per-file failure inventory

Re-derived from `.factory/tmp/native-baseline/test.stdout`:

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

Classification:

- **Environmental** (154): all 154 hit the `RepoService.init` →
  `installGlobalSkills` → `mkdir ~/.claude/skills/swamp`
  `PermissionDenied` chain.
- **Unclassified** (6): 4 test files; root cause not yet confirmed
  but each is small enough to investigate in the characterization
  ACT.

`154 + 6 = 160` ✓

## Mechanical conservation laws (post-correction)

```
passed + failed + ignored == total
  12128 + 160 + 30 == 12318 ✓
classified_failures == failed
  154 + 6 == 160 ✓
board_state agrees with ACT_state
  SWAMP-BASELINE01 == CLOSED == ACT §22 closed commit ✓
digest hygiene agrees with closure hygiene
  git diff --check returns no whitespace errors ✓
manifest agrees with prose
  manifest.json.unclassifiedFailures == 6 == prose ✓
```

All conservation laws hold. Verdict: `EVIDENCE_PACKET_CORRECTED`.

## What this ACT does NOT do

- It does not repair, refactor, or "fix" anything in Swamp.
- It does not re-run the native checks (the original outputs in
  `.factory/tmp/native-baseline/` are preserved as the runtime
  evidence; only their interpretation in the packet was wrong).
- It does not produce a fresh attestation — that requires a
  credentials-bearing environment, carried into `SWAMP-TEST-CHAR01`.

## Negative claims

```
NO_SWAMP_PRODUCTION_CODE_CHANGED=true
NO_UPSTREAM_PR_CREATED=true
NO_UPSTREAM_LIFECYCLE_STATE_WRITTEN=true
NO_ATTESTATION_FORGED=true
NO_SKIPPED_STEP_COUNTED_AS_EXECUTED=true
NO_MODEL_REVIEW_COUNTED_AS_DETERMINISTIC=true
BASELINE_SUBJECT_EXACTLY_IDENTIFIED=true
EVIDENCE_PACKET_MECHANICALLY_CONSISTENT=true
```

All true. The correction only touched `.factory/**`.

## Recommended next ACT

`SWAMP-TEST-CHAR01` — characterize the 160 failures in a controlled
writable-home environment using `TMP_HOME=$(mktemp -d)` plus
`HOME=$TMP_HOME SWAMP_HOME=$TMP_HOME/.swamp`. Per the reviewer's
proposal:

```bash
TMP_HOME="$(mktemp -d)"
HOME="$TMP_HOME" \
SWAMP_HOME="$TMP_HOME/.swamp" \
DENO_DIR=/tmp/swamp-deno-char \
deno task test
```

Then compare:

- A. current host environment (already captured in BASELINE01)
- B. isolated writable HOME
- C. isolated targeted reruns of every previously failing test file

Repeat suspicious tests (`doctor_audit`, `fetch_otlp*`,
`extension_quality_checker`, `data/query`) at least 20–50 times each
to distinguish environmental explanations from reproducible
defects from flake.

Exit criteria for `SWAMP-TEST-CHAR01`:

- `TEST_SUITE_ENVIRONMENTALLY_EXPLAINED` — all 160 disappear in
  writable HOME.
- `TEST_SUITE_HAS_REPRODUCIBLE_DEFECTS` — exact tests and
  reproductions recorded.
- `TEST_SUITE_FLAKY` — repetition statistics recorded.

Independent of which path the test-characterization ACT takes, the
`SWAMP-BASELINE01` packet is now trustworthy enough to support
subsequent investigation.
