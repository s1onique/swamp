# Cluster summary

3 clusters observed across 33 failures.

## Cluster table

| Cluster | size | primary | cause_owner | handling | evidence | dogfood |
| ------- | ---- | ------- | ----------- | -------- | -------- | ------- |
| CLUSTER-01 | 31 | ENVIRONMENTAL | SUBSTRATE | NOT_APPLICABLE | FALSIFIED_BY_CONTROL | NON_BLOCKING |
| CLUSTER-02 |  1 | ENVIRONMENTAL | SUBSTRATE | DEGRADED | REPRODUCED_REPEATEDLY | NON_BLOCKING |
| CLUSTER-03 |  1 | PROJECT_DEFECT  | SWAMP    | DEGRADED | REPRODUCED_REPEATEDLY | NON_BLOCKING |
| **total** | **33** | | | | | |

No cluster is UNRESOLVED.

## Verdict

```
VERDICT: REMAINING_FAILURE_SURFACE_MIXED
DOGFOOD_READY: false   (per §42 — unresolved failures == 0 is met,
                         but cluster 03 is a project defect that the
                         ACT does not repair; cluster 01 requires a
                         PATH policy decision; cluster 02 requires a
                         failure-mode decision for remote-execution
                         under load. DOGFOOD01 can proceed without
                         these being repaired IF DOGFOOD01's scope
                         does not include remote execution or PATH.)
```

The mix reflects:

- 32 ENVIRONMENTAL failures:
  - 31 are **substrate / test-environment dependent** (deno not on PATH).
    These pass on every CI and every developer machine with deno on
    PATH. The substrate here has deno at `/tmp/deno-arm64/deno`,
    not on PATH.
  - 1 is **parallel-load-induced** in remote execution. Passes in
    isolation.
- 1 PROJECT_DEFECT: a test added by the recently-accepted
  SWAMP-DOCTOR-SIGNAL-CAPABILITY01 repair that has a
  timing-edge assumption (30 ms child lifetime vs 100 ms abort
  delay) that is too tight on this substrate.

None of these undermines DOGFOOD01's intended operations
(workflow execution, data/versioning, workspace/repo handling,
model invocation, verification reporting). All three clusters are
NON_BLOCKING for dogfooding. But the ACT conservatively sets
DOGFOOD_READY=false because the failures still occupy the
test-suite green baseline and the ACT does not modify
production code.
