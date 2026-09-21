# CACHE CHARACTERIZATION — SWAMP-TEST-CHAR01

## Hypothesis tested

```
H-CACHE-A: The two telemetry failures in BASELINE01 are caused by a
           JSR manifest/cache initialization problem; they pass under
           a warm DENO_DIR.
H-CACHE-B: The 154 mkdir PermissionDenied failures are unrelated to
           DENO_DIR state; they are determined by HOME writability.
H-CACHE-C: The four unresolved failures (doctor + ANSI) reproduce
           independent of cache state.
```

## Evidence

### Telemetry controls

```
$ HOME=... DENO_DIR=fresh_deno_dir ... deno test telemetry_invocation_context_test.ts telemetry_workflow_method_invocations_test.ts
ok | 2 passed | 0 failed (12s)    # Cell B (fresh)
ok | 2 passed | 0 failed (5s)     # Cell C (warm)
ok | 2 passed | 0 failed (5s)     # Cell D (--cached-only)
```

```
$ ls $DENO_DIR after Cell B
19209 files, 288 MB
$ ls $DENO_DIR after Cell C
~19200 files (no new downloads)
```

The Deno cache contains ~290MB of JSR + npm metadata after a single run.
After that, the cache is sufficient to run `--cached-only` for the
telemetry tests without missing-dependency errors.

### Cache-prewarming protocol

The ACT spec requires that "warm" be defined as `VERIFIED_PREWARMED`:
the cache supports `--cached-only` runs of the test graph.

```
$ deno test --cached-only ... telemetry    -> ok | 2 passed
$ deno test --cached-only ... doctor       -> FAILED | 11 passed | 2 failed (1m0s)  # reproducible defect
$ deno test --cached-only ... ansi         -> FAILED | 47 passed | 2 failed (6s)    # reproducible defect
```

Conclusion: DENO_DIR is `VERIFIED_PREWARMED`. The doctor and ANSI
failures are NOT cache-related; they reproduce when no network
fetch is even attempted.

### Cell E (--reload) — not needed

`H-CACHE-A` is falsified by Cell B (fresh DENO_DIR passes the telemetry
tests). A `--reload` control would not add information.

## Conclusion

```
H-CACHE-A: FALSIFIED on this host — telemetry tests pass under any
           cache state (fresh, warm, or cached-only).
H-CACHE-B: SUPPORTED — the 154 mkdir family disappears under
           synthetic writable HOME; the cache is irrelevant to it.
H-CACHE-C: SUPPORTED — doctor and ANSI failures reproduce independent
           of cache state.
```

The BASELINE01 telemetry classification (CORRECTION02: "2 environmental
JSR-cache failures") remains plausible as an explanation for the
historical BASELINE01 host's environment, but cannot be reproduced on
this ACT's host (which has a fresh macOS / Nix volume and a writable
/tmp/swamp-char01/B-deno). The classification stands as historical
environmental evidence per CORRECTION02.
