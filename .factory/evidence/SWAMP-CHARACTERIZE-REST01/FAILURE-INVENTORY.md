# Failure inventory

## Conservation

```
runner_passed       = 12 287
runner_failed       =     33
runner_ignored      =     30
runner_total        = 12 350   (passed + failed + ignored, exact)

classification_conservation:
  ENVIRONMENTAL       = 32
  PROJECT_DEFECT      =  1
  ------------------  = 33

cluster_conservation:
  CLUSTER-01  = 31
  CLUSTER-02  =  1
  CLUSTER-03  =  1
  ----------- = 33
```

All observed failures have been assigned a primary
classification. **NO_UNKNOWN_RED=true**.

## Inventory rows (n=33)

See `failures.json` for the machine-readable form. A summarized
list grouped by cluster:

### CLUSTER-01 — `deno` not on PATH (31 failures)

Primary classification: ENVIRONMENTAL (CAUSE_OWNER=SUBSTRATE)
Evidence strength: FALSIFIED_BY_CONTROL

31 failures spread across 5 test files. All 31 share the same
NotFound signature (`Failed to spawn 'deno': entity not found`)
and reproduce as 0 failures under `PATH="/tmp/deno-arm64:$PATH"`.

#### user_datastore_loader_test.ts (7 failures)
- F-02 `UserDatastoreLoader - loads valid datastore from temp directory`
- F-03 `UserDatastoreLoader - loads valid non-@ datastore type`
- F-04 `UserDatastoreLoader - invalidates bundle cache when dependency changes`
- F-05 `UserDatastoreLoader buildIndex rebundles when source content changes with preserved mtime (#128)`
- F-06 `UserDatastoreLoader buildIndex rebundles when transitive dep content changes with preserved mtime (#128)`
- F-07 `UserDatastoreLoader: registerLazyFromCatalog skips validation_failed rows (swamp-club#209)`
- F-08 `UserDatastoreLoader.bundleAndIndexOne: returns datastore metadata without writing catalog rows (Pin 1)`

#### extension_loader_subprocess_test.ts (7 failures)
- F-09 `module-reload(model): distinct fingerprints see fresh module`
- F-10 `module-reload(vault): distinct fingerprints see fresh module`
- F-11 `module-reload(datastore): distinct fingerprints see fresh module`
- F-12 `module-reload(report): distinct fingerprints see fresh module`
- F-13 `fingerprint-collision: same fingerprint returns same cached module`
- F-14 `fingerprint-divergence: same path different fingerprints are distinct`
- F-15 `empty-fingerprint: no query parameter produces bare URL import`

#### user_vault_loader_test.ts (11 failures)
- F-16 `UserVaultLoader - loads valid vault from temp directory`
- F-17 `UserVaultLoader - allows @swamp/* namespace for local vaults`
- F-18 `UserVaultLoader - loads valid non-@ vault type`
- F-19 `UserVaultLoader - allows swamp/* namespace for local vaults`
- F-20 `UserVaultLoader - invalidates bundle cache when dependency changes`
- F-21 `UserVaultLoader - allows si/* namespace for local vaults`
- F-22 `UserVaultLoader buildIndex rebundles when source content changes with preserved mtime (#128)`
- F-23 `UserVaultLoader buildIndex rebundles when transitive dep content changes with preserved mtime (#128)`
- F-24 `UserVaultLoader: registerLazyFromCatalog skips validation_failed rows (swamp-club#209)`
- F-25 `UserVaultLoader.bundleAndIndexOne: returns vault metadata without writing catalog rows (Pin 1)`
- F-26 `loadSingleType: promotes lazy vault entry to fully loaded`

#### subprocess_harness_test.ts (5 failures)
- F-28 `spawnExtensionProcess: starts subprocess and imports a bundle`
- F-29 `importInSubprocess: distinct fingerprints produce distinct modules`
- F-30 `importInSubprocess: same fingerprint returns cached module`
- F-31 `importInSubprocess: empty fingerprint produces bare URL`
- F-32 `measureHeap: returns heap size`

#### resolve_command_test.ts (1 failure)
- F-27 `defaultCommandResolver: resolves a binary that exists (deno)`

### CLUSTER-02 — Remote execution under full-suite parallel load (1 failure)

Primary classification: ENVIRONMENTAL (CAUSE_OWNER=SUBSTRATE — parallel resource pressure)
Evidence strength: REPRODUCED_REPEATEDLY (3 isolated re-runs all green; full-suite load red)

- F-33 `integration/remote_execution_test.ts → remote execution: enroll over a real socket, dispatch, verbs, leases, scheduling, cancel`

### CLUSTER-03 — Doctor-portable terminal-race (1 failure)

Primary classification: PROJECT_DEFECT (CAUSE_OWNER=SWAMP)
Evidence strength: REPRODUCED_REPEATEDLY (3 isolated re-runs, identical 1-failed outcome each)

- F-01 `src/cli/commands/doctor_audit_test.ts → runChildWithAbort: portable — terminal race returns benign already-terminal outcome, not delivery error`

## What is *not* failing

- All ANSI-output tests (after SWAMP-ANSI-OUTPUT01 repair): **PASS**
  (extension_quality_checker_test.ts: 58 passed | 0 failed; broader
  extension group: 129 passed | 0 failed).
- All real-signal doctor tests (with capability gating): **PASS**
  (`CAN_SIGNAL_CHILD=false reason=PermissionDenied` capability
  probe correctly marks these as substrate-gated; portable
  tests pass).
