# CLUSTER-02 — Remote-execution integration failure under full-suite parallel load (1 test)

## Mechanism

```
integration/remote_execution_test.ts:
  "remote execution: enroll over a real socket, dispatch,
   verbs, leases, scheduling, cancel"
```

The test mints a worker enrollment token, enrolls a worker
(`runWorker(...)`), runs dozens of `orchestrator.dispatchService.executeRemote(...)`
calls plus reads/writes against the unified data repo and vault,
then asserts the worker returns to idle, and finally tears down
via `workerStop.abort()` and `orchestrator.shutdown()` in `finally`.

Under full-suite parallel load the test ran for **10 m 5 s** before
Deno emitted its FAILED marker. The test's natural isolated runtime is
~4 s, indicating the dispatch loop never converged.

## Root cause signature

Captured in `full/stdout` (line ~19722):

```
error: Error: RPC channel is closed
      return Promise.reject(new Error("RPC channel is closed"));
                          ^
    at RpcChannel.call (.../src/domain/remote/rpc_channel.ts:150:29)
    at WorkerGateway.dispatch (.../src/serve/worker_gateway.ts:346:39)
    at async DispatchService.#dispatchOnce (.../src/serve/dispatch_service.ts:531:22)
    at async DispatchService.executeRemote (.../src/serve/dispatch_service.ts:358:26)
    at async .../integration/remote_execution_test.ts:458:28
```

The harness log shows:

```
serve·worker-gateway: Enrollment token for "it-worker" expired — disconnecting
serve·worker-gateway: Reconnection grace window expired for "it-worker"
```

i.e. the worker's enrollment token expired while the dispatch was
still in flight. The RPC channel was then closed by the orchestrator's
reconnection grace expiry logic before the dispatch call resolved.

## Isolation evidence

```
test integration/remote_execution_test.ts    => 5 passed | 0 failed (4s) [run 1]
test integration/remote_execution_test.ts    => 5 passed | 0 failed (4s) [run 2]
test integration/remote_execution_test.ts    => 5 passed | 0 failed (4s) [run 3]
test integration/remote_execution_test.ts --parallel
                                            => 5 passed | 0 failed (4s) [run 4 with --parallel]
```

(Raw: `clusters/CLUSTER-02/isolation.stdout`.)

The failure reproduces **only under full-suite parallel load**, not
under isolated or parallel-of-this-file load. This is parallel
cross-test interference under heavy resource pressure.

## Classification

```
PRIMARY:          ENVIRONMENTAL  (parallel full-suite load)
CAUSE_OWNER:      SUBSTRATE      (full-suite parallel resource pressure that cannot
                                 be reproduced by isolated re-runs)
HANDLING:         DEGRADED       (RPC channel closes on reconnection expiry mid-call)
EVIDENCE:         REPRODUCED_REPEATEDLY   (N=3 isolated runs all green; N=1 full-suite
                                           run red; not enough full-suite N to call flaky)
DOGFOOD_IMPACT:   NON_BLOCKING   (DOGFOOD01's own remote-execution needs are not yet
                                 defined; this is a pre-existing test-suite fragility)
```

## Why ENVIRONMENTAL not FLAKY

Flaky requires N>=5 with mixed outcomes at the same machine/same
conditions. Only one full-suite run completed under the policy
(NATURAL_COMPLETION=true is required for a run to count at all —
§48 explicitly forbids undirected suite repetition). The isolated
runs are uniformly green. The single contradictory observation is
the one full-suite run. This is **parallel interference under load**,
which the doctrine recognizes as a parallel-load-driven substrate
effect, not a property of the test under stable conditions.

## Production-code change recommendation

Optional follow-up: harden `RpcChannel.call` so a closed peer
during dispatch surfaces a specific error type (distinct from
generic transport failure) and the orchestrator suppresses
expiry during in-flight dispatches.

But this is NOT in this ACT's scope and would only be useful if
DOGFOOD01 intends to enroll remote workers under full-suite
load, which the planned DOGFOOD01 ACT (§44 of baseline plan) does
not list.

## Raw evidence

- `.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stdout` lines 19682, 19722
- `.factory/tmp/SWAMP-CHARACTERIZE-REST01/clusters/CLUSTER-02/isolation.stdout`
