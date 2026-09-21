# CLUSTER-01 — `deno` not on PATH (31 tests)

## Mechanism

All 31 failures originate from a single substrate gap:
the local Deno 2.9.7 binary exists at
`/tmp/deno-arm64/deno` (and `/tmp/deno-bin/deno`) but is **not on
the default shell `PATH`**. Multiple test suites shell out to
`deno` via `new Deno.Command("deno", ...)` or via
`defaultCommandResolver().resolve("deno")`, both of which depend
on PATH resolution.

The captured runtime error is uniform:

```
error: NotFound: Failed to spawn 'deno': entity not found
  const process = command.spawn();
  ...
  at spawnExtensionProcess (.../subprocess_harness.ts:55:27)
```

Affected test files (5):

- `src/infrastructure/testing/subprocess_harness_test.ts` (5)
- `src/domain/datastore/user_datastore_loader_test.ts` (7)
- `src/domain/vaults/user_vault_loader_test.ts` (11)
- `src/domain/extensions/extension_loader_subprocess_test.ts` (7)
- `src/infrastructure/process/resolve_command_test.ts` (1)

These 31 cover the full population of `... h => spawnExtensionProcess() ...`
and `Deno.Command("deno", ...)` consumers in the test suite.

## Root cause signature

```
NotFound: Failed to spawn 'deno': entity not found
```

## Falsification (the controlling experiment)

Run the same 5 test files with `PATH="/tmp/deno-arm64:$PATH"`:

```
PATH="/tmp/deno-arm64:$PATH" deno test <5 test files>
=> ok | 51 passed | 0 failed (1s)
```

(Raw: `clusters/CLUSTER-01/isolation-with-deno-on-path.stdout`.)

This proves the failures are **PATH-dependent, not project
defects**.

## Classification

```
PRIMARY:          ENVIRONMENTAL
CAUSE_OWNER:      SUBSTRATE   (PATH lacks deno)
HANDLING:         NOT_APPLICABLE  (project code does what it should)
EVIDENCE:         FALSIFIED_BY_CONTROL
DOGFOOD_IMPACT:   NON_BLOCKING  (project handles PATH-resolved deno in production; sandbox is the only place PATH is missing)
```

## Production-code change recommendation

Do not patch this. Production behaviors would not improve by
patching; the tests' reliance on a globally-resolvable `deno`
binary is intentional (matches the production harness contract
"every CI runner has deno on PATH").

A future ACT could request that `deno.json` add a
`unstable: ["deno-on-PATH"]` test-mode guard, but that would
defeat the test purpose.

## Why not PROJECT_DEFECT

The test environment intentionally mirrors the production
trust contract: Deno on PATH is a documented test-runtime
requirement. The substrate here is non-standard because
Nix-managed home directories put the operator's deno binaries
elsewhere.

## Raw evidence

- `.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/stdout` (full run)
- `.factory/tmp/SWAMP-CHARACTERIZE-REST01/clusters/CLUSTER-01/isolation-with-deno-on-path.stdout` (control)
- 31 failure rows under `f.cluster_id == "CLUSTER-01"` in `failures.json`
