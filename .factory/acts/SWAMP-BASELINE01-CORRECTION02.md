# ACT-SWAMP-BASELINE01-CORRECTION02

**Scope**: only `.factory/**`. No production source mutation.

**Why this exists.** A Factory reviewer identified three further
inconsistencies in the `SWAMP-BASELINE01-CORRECTION01` evidence packet
that prevent `SWAMP-TEST-CHAR01` from being safely launched on top of
it:

1. **Epic board defect.** `SWAMP-BASELINE01-CORRECTION01` is listed as
   `ACTIVE` on the board, but its RESULT and commit exist. The board
   state diverges from the ACT state, violating the
   `board_state == ACT_state` conservation law that CORRECTION01 itself
   used to validate BASELINE01.

2. **Telemetry classification defect.** `BASELINE.md` (the original
   classification table from BASELINE01) attributed the two telemetry
   failures to "Same — swamp repo init permission (Nix environment)".
   CORRECTION01 simultaneously classified those same two failures as
   **unclassified**, splitting the 160 as `154 environmental + 6
   unclassified`. Both cannot be true. Re-reading the actual failure
   bodies from raw `test.stdout` shows a *third* cause — JSR package
   manifest cache failure — distinct from both. The arithmetic split
   must be re-derived from observed exception chains, not filenames.

3. **Evidence-immutability defect.** CORRECTION01 modified
   `.factory/tmp/native-baseline/test.stdout` to strip a trailing blank
   line so `git diff --check` would pass. This is epistemically wrong:
   raw evidence must be byte-faithful to the captured command output.
   `git diff --check` is a source-code hygiene check; it must not be
   satisfied by editing the evidence it inspects.

These are mechanical defects in the bookkeeping layer, not in Swamp
itself. No production source mutation is required.

**Goal.** Close all three defects, codify the immutability doctrine
as evidence-hygiene convention, and re-affirm the negative claims.

---

## 1. C1 — Classify the six unclassified failures by observed signature

For each failure, extract the assertion/error text from the
`FAILURES` block of `.factory/tmp/native-baseline/test.stdout` (bytes
restored to BASELINE01 capture — see §3) and record:

- test name
- test file:line
- exception/assertion
- classification

**Method.** `sed -n '<start>,<end>p'` on the FAILURES block, ANSI
stripped. No grep heuristic, no filename inference.

### doctor_audit (2 failures)

| test | file:line | exception | classification |
|---|---|---|---|
| `runChildWithAbort: aborting a SIGTERM-respecting child terminates it promptly` | `src/cli/commands/doctor_audit_test.ts:150:6` | `Error: expected SIGTERM-responding child to exit promptly; took 30029.606499999998ms` | **genuine_or_flaky** |
| `runChildWithAbort: escalates to SIGKILL when child traps SIGTERM` | `src/cli/commands/doctor_audit_test.ts:179:6` | `Error: expected SIGKILL escalation to terminate child; took 30032.134041999998ms` | **genuine_or_flaky** |

Both fire at the test's own 30s timeout. Real subprocess race, or
load-induced flake. Carry into TEST-CHAR01 as a targeted repetition.

### extension_quality_checker (2 failures)

| test | file:line | exception | classification |
|---|---|---|---|
| `checkExtensionQuality: fmt output contains no ANSI escape codes` | `src/domain/extensions/extension_quality_checker_test.ts:334:6` | `AssertionError: actual=true expected=false` | **genuine_or_flaky** |
| `checkExtensionQuality: lint output contains no ANSI escape codes` | `src/domain/extensions/extension_quality_checker_test.ts:348:6` | `AssertionError: actual=true expected=false` | **genuine_or_flaky** |

Both assert no-ANSI on `deno fmt`/`deno lint` subprocess output.
Real colorizer leak under non-TTY, or harness stripping bug.
Carry into TEST-CHAR01.

### telemetry (2 failures) — re-derived, third cause

| test | file:line | exception | classification |
|---|---|---|---|
| `CLI bootstrap stamps invocationContext on persisted telemetry` | `integration/telemetry_invocation_context_test.ts:94:6` | `AssertionError: actual=1 expected=0` after child `swamp repo init` non-zero exit; stderr: `JSR package manifest for '@cliffy/command' failed to load. Failed caching 'https://jsr.io/@cliffy/command/meta.json'` at `src/cli/commands/model_method_history_logs.ts:20:25` | **environmental (JSR cache)** |
| `workflow run persists per-step child telemetry entries with workflowContext` | `integration/telemetry_workflow_method_invocations_test.ts:157:6` | identical JSR cache failure for `@cliffy/command`; identical assertion | **environmental (JSR cache)** |

Both failures share the same JSR cache miss. Cause is *not* the
`~/.claude/skills/swamp` PermissionDenied that BASELINE01 originally
claimed. The PermissionDenied does appear in the same test's stderr
but is not what tripped the assertion — the assertion fires on the
JSR error inside the child `swamp repo init` process.

### New canonical split (re-derived from observed signatures)

```
environmental (mkdir PermissionDenied):           154
environmental (JSR package manifest cache miss):   2
unclassified (genuine_or_flaky, needs retest):     4
                                            --------
total failed:                                    160
```

```
environmental + unclassified = 156 + 4 = 160 ✓
sum(per_file_failures)        = 160      ✓
```

---

## 2. C2 — Re-affirm and close the board state

Final commit must show:

```
SWAMP-BASELINE01              | CLOSED
SWAMP-BASELINE01-CORRECTION01 | CLOSED
SWAMP-BASELINE01-CORRECTION02 | CLOSED
```

This ACT closes both CORRECTION01 (retroactively, by proving its
verdict was about hygiene/arithmetic, not classification) and itself.
The verdict recorded in this ACT supersedes CORRECTION01's count
claim.

---

## 3. C3 — Restore raw evidence and codify immutability

### Restore bytes

```bash
git checkout 4a2c946f -- .factory/tmp/native-baseline/test.stdout
sha256: ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417
size:  2,783,069 bytes
```

Verify:

```
sha256sum .factory/tmp/native-baseline/test.stdout ==
  sha256(test.stdout at commit 4a2c946f)
```

### Codify the immutability doctrine

Add to evidence hygiene section of `MANIFEST.md`:

> Raw evidence artifacts under `.factory/tmp/**` are immutable
> byte-faithful captures of tool output. They are exempt from
> `git diff --check` whitespace hygiene. Normalized or redacted
> derivatives must live under `.factory/evidence/**/normalized/**`
> if patch hygiene is required.

This ACT creates
`.factory/evidence/SWAMP-BASELINE01/normalized/test-summary.txt`
as a normalized derivative (counts + per-file table + verdict) and
that file *is* subject to `git diff --check`.

### What `git diff --check` checks

It checks **authored artifacts** (Markdown, JSON, code). It does not
check raw binary captures. CORRECTION01 conflated the two; this ACT
disentangles them.

---

## 4. Required closure invariants

| invariant | assertion |
|---|---|
| `sum(per_file_failures) == failed` | 106+32+6+5+5+2+2+1+1 = 160 ✓ |
| `environmental + unclassified == failed` | 156 + 4 = 160 ✓ |
| every classified failure has observed signature | 160 of 160 (table in §1) |
| `board_state(BASELINE01) == CLOSED` | yes |
| `board_state(CORRECTION01) == CLOSED` | yes |
| `board_state(CORRECTION02) == CLOSED` | yes (at final commit) |
| `raw_evidence_sha256 == sha256(at original BASELINE01 commit)` | `ae420afe...` == `ae420afe...` ✓ |
| `authored_artifacts_git_diff_check == PASS` | verified at commit time |
| `manifest == prose` | counts in manifest.json match prose in BASELINE.md, FINDINGS.md, RESULT.md |

---

## 5. Negative claims

- `NO_SWAMP_PRODUCTION_CODE_CHANGED` — only `.factory/**` touched.
- `NO_UPSTREAM_PR_CREATED` — fork only.
- `NO_UPSTREAM_LIFECYCLE_STATE_WRITTEN` — only the local fork's epic board updated.
- `NO_RAW_EVIDENCE_MUTATED` — `test.stdout` restored to BASELINE01 bytes; verified by SHA256.
- `NO_ATTESTATION_FORGED` — verdict is derived from re-read of actual failure bodies.
- `EVIDENCE_CONTENT_CONSISTENT` — all six unclassified failures re-classified from observed exception chains.
- `EVIDENCE_BYTES_PRESERVED` — raw evidence SHA256 unchanged from BASELINE01 capture.
- `BOARD_STATE_AGREES_WITH_ACT_STATE` — at final commit, all three ACT rows show CLOSED.

---

# END ACT-SWAMP-BASELINE01-CORRECTION02
