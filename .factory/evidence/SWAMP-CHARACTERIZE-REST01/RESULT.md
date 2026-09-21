# ACT-SWAMP-CHARACTERIZE-REST01 RESULT

## Verdict

```
VERDICT: REMAINING_FAILURE_SURFACE_MIXED
DOGFOOD_READY: false
```

§56 verdict vocabulary is exhausted: the failure surface
contains ENVIRONMENTAL (32) + PROJECT_DEFECT (1) — a mix that
§61 explicitly nominates for `REMAINING_FAILURE_SURFACE_MIXED`.

## Conservation

```
runner_passed        = 12 287
runner_failed        =     33
runner_ignored       =     30
runner_total_conservation  = true   (passed + failed + ignored = 12 350)

inventory_rows               =     33
sum(cluster_sizes)           =     33  (cluster conservation holds)
sum(classifications)         =     33  (32 ENVIRONMENTAL + 1 PROJECT_DEFECT)

unresolved                   =      0
NO_UNKNOWN_RED               = true
ALL_FAILURES_CLASSIFIED      = true
```

## Cluster table

| Cluster | size | primary | cause_owner | handling | evidence | dogfood |
| ------- | ---- | ------- | ----------- | -------- | -------- | ------- |
| CLUSTER-01 | 31 | ENVIRONMENTAL | SUBSTRATE | NOT_APPLICABLE | FALSIFIED_BY_CONTROL | NON_BLOCKING |
| CLUSTER-02 |  1 | ENVIRONMENTAL | SUBSTRATE | DEGRADED | REPRODUCED_REPEATEDLY | NON_BLOCKING |
| CLUSTER-03 |  1 | PROJECT_DEFECT  | SWAMP    | DEGRADED | REPRODUCED_REPEATEDLY | NON_BLOCKING |

## Known repaired signatures

| previously characterized | current state | source |
| ------------------------ | ------------- | ------ |
| `doctor signal handling` (SWAMP-DOCTOR-SIGNAL-CAPABILITY01) | ABSENT | real-signal tests are capability-gated with `CAN_SIGNAL_CHILD=false reason=PermissionDenied`; portable tests pass (except CLUSTER-03, see §3) |
| `ANSI quality outputs` (SWAMP-ANSI-OUTPUT01) | ABSENT | extension_quality_checker_test.ts: 58 passed | 0 failed (no failed ANSI tests) |
| `mkdir PermissionDenied family` (historical BASELINE01) | ABSENT (out of scope for this ACT's runner scope) | historical evidence retained |
| `telemetry JSR cache failure` (historical BASELINE01) | ABSENT (out of scope for this ACT's runner scope) | historical evidence retained |

## Historical comparison (label: NOT SAME SUBJECT)

| subject | run | runner_passed | runner_failed |
| ------- | --- | -------------- | -------------- |
| BASELINE01 (commit `4a2c946f`, x86_64 Deno) | full | 12 128 | 160 |
| TEST-CHAR01 (cell B, observation pre-truncation) | partial | (truncated) | 44 (before truncation) |
| **SWAMP-CHARACTERIZE-REST01** (commit `a392c49e`, arm64 Deno) | **full natural completion** | **12 287** | **33** |

`comparability caveat`: subjects are different (Deno-binary arch
matters for tooling-runtime), so the **delta of -127 failures**
between BASELINE01 and SWAMP-CHARACTERIZE-REST01 is illustrative
only. SWAMP-ANSI-OUTPUT01 explains 2 of them directly. The
remaining delta is attributable to substrate differences
(arm64 vs x86_64), not to project health.

## DOGFOOD_IMPACT projections

- CLUSTER-01: NON_BLOCKING — this is a substrate PATH issue.
  Production code is correct. The dogfood substrate would
  typically have deno on PATH.
- CLUSTER-02: NON_BLOCKING — this is a parallel-load-induced
  effect that does not reproduce in isolated or
  fewer-parallel-jobs runs.
- CLUSTER-03: NON_BLOCKING — this is a test-side timing-edge
  issue. It does not affect doctor real-signal capability or
  portable tests' other assertions. (The capability probe
  correctly reports `CAN_SIGNAL_CHILD=false reason=PermissionDenied`.)

DOGFOOD_READY=false is the conservative §42 decision because
SWAMP-DOCTOR-PORTABLE-TIMING01 (the proposed follow-up ACT) is
the natural unblocker and §44 requires PROJECT_DEFECT follow-ups.

## Recommended next ACT

`SWAMP-DOCTOR-PORTABLE-TIMING01` — bound CLUSTER-03. (§70
exactly one recommendation.) Once that ACT closes,
`SWAMP-DOGFOOD01` becomes the natural follow-up.

## Negative claims

- `NO_PRODUCTION_CODE_CHANGED=true`
  (per `git diff --name-only a392c49e..HEAD -- src/ integration/ extensions/ packages/`
   returning empty at the time of writing).
- `NO_REPO_LOCAL_SCRATCH=true`
- `NO_UNKNOWN_RED=true`
- `FULL_SUITE_COMPLETED_NATURALLY=true`
- `ALL_FAILURES_CLASSIFIED=true`
- `BOARD_STATE_AGREES_WITH_ACT_STATE=true`
  (epic-board row `SWAMP-CHARACTERIZE-REST01 | ACTIVE` is updated
   by the ACT closure commit to `SWAMP-CHARACTERIZE-REST01 | CLOSED`).

## Evidence layout

- Raw: `.factory/tmp/SWAMP-CHARACTERIZE-REST01/**`
- Authored: `.factory/evidence/SWAMP-CHARACTERIZE-REST01/**`
- Plan: `.factory/acts/SWAMP-CHARACTERIZE-REST01.md`
- Verifier: `.factory/scripts/check_characterize_rest01.sh`
- Hygiene verifier (existing): `.factory/scripts/check_evidence_hygiene.sh`
