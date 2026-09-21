# CLUSTER-02 (corrected) — `RPC channel is closed`

> **REVISED CLASSIFICATION.** This cluster was initially labelled
> ENVIRONMENTAL with `evidence=REPRODUCED_REPEATEDLY` in the
> SWAMP-CHARACTERIZE-REST01 closure. A reviewer-discovered audit
> showed that the evidence strength was overstated. The corrected
> classification below was obtained after running the minimum
> control (DENO_JOBS=1/2/default isolated; parallel single-file;
> neighborhood co-runs) under
> ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION01.

| Field | Value |
|---|---|
| Cluster ID | CLUSTER-02 |
| Count | 1 |
| Test name | remote execution: enroll over a real socket, dispatch, verbs, leases, scheduling, cancel |
| Test file | integration/remote_execution_test.ts:322 |
| Runner line | Error: RPC channel is closed at src/domain/remote/rpc_channel.ts:150 via WorkerGateway.dispatch:346 |
| Primary classification | **UNRESOLVED** |
| Cause owner | **UNKNOWN** |
| Evidence | **OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD** (NOT_REPRODUCED_ISOLATED) |
| Dogfood blocker | yes (UNKNOWN red flag per readiness gate) |
| Handling | DEGRADED — awaiting future SWAMP-REMOTE-PARALLEL-INTERFERENCE01 |

## What changed since the prior ACT

| Datum | Prior ACT | Corrected ACT | Source |
|---|---|---|---|
| Evidence | REPRODUCED_REPEATEDLY | OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD | Job 1 controls |
| Cause owner | SUBSTRATE | UNKNOWN | no control reproduces |
| Primary | ENVIRONMENTAL | UNRESOLVED | matches evidence |
| no_unknown_red | true | false | one UNRESOLVED present |

## Job 1 controls (correction ACT)

All runs under
HOME=/tmp/swamp-char-rest01-correction01/home,
DENO_DIR=/tmp/swamp-char-rest01-correction01/deno,
TMPDIR=/tmp, PATH=/tmp/deno-arm64:$PATH.

| # | Run | Files | --parallel | DENO_JOBS | Result |
|---|---|---|---|---|---|
| 1a | isolated single | integration/remote_execution_test.ts | no | 1 | ok 5 passed 0 failed (4s) |
| 1b | isolated single | same | no | 2 | ok 5 passed 0 failed (4s) |
| 1c | isolated single | same | no | default | ok 5 passed 0 failed (4s) |
| 1c' | isolated single | same | yes | default | ok 5 passed 0 failed (4s) x 3 runs |
| 1d-1 | neighborhood co-run | cluster-01 set (5 files) + remote_exec | yes | default | FAILED 55 passed 1 failed (4s) |
| 1d-2 | neighborhood co-run | same | yes | default | ok 56 passed 0 failed (5s) |
| 1d-3 | neighborhood co-run | same | yes | default | ok 56 passed 0 failed (4s) |
| 1e | worker-class co-run | 9 worker-related test files | yes | default | ok 328 passed 0 failed (10s) |
| 1f | full integration/ | every integration test | yes | default | ok 363 passed 0 failed (24s) |
| 1g | original full suite | full native deno test | yes | default | 33 failed including cluster-02 RPC channel close |

## Interpretation

The cluster-02 failure was NOT reproduced under any of:
- sequential (DENO_JOBS=1) or low-parallel (DENO_JOBS=2) isolated
  runs,
- parallel isolated runs of just the failing file (3/3 passes),
- parallel co-runs of related test classes (worker-class, full
  integration/).

The only context that reproduces the failure is the original full
native suite at scale (~12,287 tests across src/, integration/, and
extensions/). That context is too large to attribute causality
without further narrowing. The earlier claim that parallel resource
pressure is the cause is a hypothesis, NOT a control-confirmed fact.

The neighborhood co-run (Job 1d) did reproduce ONE failure on the
first of three attempts — but the failure was in
user_datastore_loader_test.ts:69 (a cluster-01 substrate-PATH
signature, not the cluster-02 RPC failure). That is itself a
microcosm of the same flakiness pattern: under parallel pressure,
cluster-01's already-known substrate sensitivity can occasionally
manifest as a DIFFERENT assertion failure (loaded.length 0 vs 1).
It does not implicate cluster-02.

## Why we now refuse to project cluster-02's cause

The original ACT claimed:

> CLUSTER-02 (1, ENVIRONMENTAL, cause_owner=SUBSTRATE,
> evidence=REPRODUCED_REPEATEDLY, handling=DEGRADED) — RPC channel is
> closed at WorkerGateway.dispatch:346. Reproduces ONLY under
> full-suite parallel load; isolated re-runs (N=3) and --parallel of
> single file all green.

That phrasing is logically incompatible. "Reproduces only under
full-suite load" + "isolated runs are all green" is ONE observation,
not three reproductions. The corrected evidence label
OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD is the honest description.

Three independent reproductions would have required three full-suite
runs, each isolating a different variable (e.g. with one test file
class disabled each time) and observing the failure persist. None of
that was done.

## Recommended next ACT (NOT the previously claimed one)

The original closure recommended SWAMP-DOCTOR-PORTABLE-TIMING01.
That was aimed at cluster-03, not cluster-02. For cluster-02 the
correct follow-up is:

  SWAMP-REMOTE-PARALLEL-INTERFERENCE01
  (or any ACT whose first job is: systematically bisect the full
  suite to identify the smallest set of co-running test files that,
  when executed in parallel with
  integration/remote_execution_test.ts, reproduce the
  RPC channel is closed failure at WorkerGateway.dispatch:346.)

Until that ACT closes, cluster-02 remains UNRESOLVED with
cause_owner=UNKNOWN, and no_unknown_red=false. This legitimately
keeps DOGFOOD_READY=false (not by policy assertion but by gate
mechanics).

## Raw evidence paths

- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-jobs1/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-jobs2/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-jobsdefault/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-parallel-r2/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/single-parallel-r3/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-cluster01/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-cluster01-r2/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-cluster01-r3/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/co-run-worker-class/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION01/isolated/cluster02/integration-co-run/stdout.txt
- .factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stdout (original)
