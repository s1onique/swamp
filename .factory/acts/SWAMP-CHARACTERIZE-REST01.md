# ACT-SWAMP-CHARACTERIZE-REST01

Characterize **every remaining failure** in Swamp's full native test
suite under a controlled writable execution environment, after the
accepted `SWAMP-DOCTOR-SIGNAL-CAPABILITY01` and `SWAMP-ANSI-OUTPUT01`
repairs.

## Mission (§0)

Exit objective:

```
every observed failure has an evidence-backed classification
AND
no unknown red remains
```

No production repair is authorized.

## Doctrine (§1)

> Never repair an unknown failure surface. First close the inventory.

A partial test run cannot authorize claims about the complete test
suite. The primary authority is a full native test run that reaches
Deno's own terminal summary naturally.

Required invariant: `FULL_SUITE_MUST_COMPLETE_NATURALLY=true`.

## Subject and provenance (§2)

- ACT_START_HEAD = `a392c49e1c899fbbbbf39bf84d73a8308c048eb6`
  (factory closure of SWAMP-ANSI-OUTPUT01)
- UPSTREAM_HEAD = `bcaa9695b7f27f51964a9f41587fdf112b261c89`
- UPSTREAM_MERGE_BASE = `bcaa9695b7f27f51964a9f41587fdf112b261c89`
- ORIGINAL_BASELINE_SUBJECT = `bcaa9695…`
- CHARACTERIZATION_SUBJECT_SHA = `a392c49e1c899fbbbbf39bf84d73a8308c048eb6`
  (current HEAD at ACT start)

Accepted production changes since baseline:

- `4dc6c86e` `fix(doctor): surface unavailable child signal capability`
  (SWAMP-DOCTOR-SIGNAL-CAPABILITY01 production commit)
- `a46f5c7b8` `fix(extensions): normalize external quality diagnostics`
  (SWAMP-ANSI-OUTPUT01 production commit)

Do not pretend current production tree is byte-identical to baseline.

All verdicts in this ACT bind to `a392c49e`.

## Execution-substrate binding (§3)

Recorded in `.factory/tmp/SWAMP-CHARACTERIZE-REST01/environment/substrate.txt`:

- Deno binary: `/tmp/deno-arm64/deno` — Deno 2.9.7 stable, aarch64-apple-darwin
  (NATIVE ARM64, primary per §4)
- Rosetta x86_64 fallback at `/tmp/deno-bin/deno` exists but is NOT used
  for characterization.
- Host kernel: Darwin 23.6.0 arm64.
- HOME: `/tmp/swamp-char-rest01.ipyvth/home` (synthetic writable,
  outside repo).
- DENO_DIR: `/tmp/swamp-char-rest01.ipyvth/deno` (external cache,
  prewarmed).
- TMPDIR: `/tmp`.
- DENO_JOBS: default (CPU-count workers).
- Network: available; JSR returns 200.

No secrets captured.

## Toolchain (§4)

Primary: native arm64 Deno 2.9.7.
Prior ACTs used the x86_64 binary under Rosetta; this ACT uses the
arm64 binary to satisfy §4's preference. x86_64 evidence from prior
ACTs is preserved separately and is NOT recombined into the current
canonical inventory.

## Native test command (§5)

```
SWAMP_NO_TELEMETRY=1 deno test \
  --parallel --unstable-bundle \
  --allow-read --allow-write --allow-env \
  --allow-run --allow-net --allow-sys --allow-ffi
```

Run via `deno task test` with controlled environment variables.
`--parallel` preserved.

## Scratch-state policy (§6)

- NO_REPO_LOCAL_SCRATCH=true
- EPHEMERAL_HOME_OUTSIDE_REPO=true
- EPHEMERAL_DENO_DIR_OUTSIDE_REPO=true
- Scratch root: `/tmp/swamp-char-rest01.ipyvth`

The prior `swamp-char01/` 785 MB residue was cleaned up before this
ACT began (no longer present under the repo root).

## Cache preparation (§9)

Prewarm: `deno cache --reload main.ts` (7s, exit 0, cache size 218 MB).
Cache state: VERIFIED_PREWARMED.

## Authoritative full-suite run (§10)

Captures to `.factory/tmp/SWAMP-CHARACTERIZE-REST01/full/`:
stdout, stderr, exitcode, command.txt, start.txt, end.txt, duration.txt.

`$?` captured immediately after the run finishes (delayed-$? bug
explicitly avoided).

The run is launched detached via `nohup` so external harness lifetime
cannot abort it; we poll on the exitcode file.

## Natural completion proof (§12)

`NATURAL_COMPLETION=true` recorded in `FULL-RUN.md` only if:

- Deno emitted final runner summary,
- process exit code captured,
- no external SIGTERM/SIGKILL interrupted run,
- no "tool timeout" responsible for termination.

If `NATURAL_COMPLETION=false`: `HALT_FULL_SUITE_NOT_NATURAL`.

## Failure clustering (§16)

Clusters grouped by observed failure mechanism, not directory.

Each cluster: `CLUSTER-XX`, classification, cause owner, handling
quality, evidence strength, dogfood impact.

## Classification vocabulary (§17)

Primary classification (one per failure):

```
ENVIRONMENTAL
DEPENDENCY_BEHAVIOR
PROJECT_DEFECT
FLAKY
ALREADY_REPAIRED
UNRESOLVED
```

Optional dimensions: `CAUSE_OWNER`, `HANDLING_QUALITY`. Cause owner
≠ handling quality.

## Dogfood-readiness gate (§42)

DOGFOOD_READY=true iff:

- NATURAL_COMPLETION=true
- runner failure inventory complete
- unresolved failures == 0
- every current failure classified
- every project defect has bounded follow-up ACT
- no failure undermines DOGFOOD-relevant mechanisms

## Known-repair expectation (§41)

The primary run checks whether these previously characterized
signatures remain:

- doctor signal handling (PRESENT/ABSENT after repair)
- ANSI quality outputs (PRESENT/ABSENT after repair)
- mkdir PermissionDenied family (historical baseline)
- telemetry JSR cache failure (historical baseline)

## Mechanical closure invariants (§63)

Verified by `.factory/scripts/check_characterize_rest01.sh` and
`.factory/scripts/check_evidence_hygiene.sh`.

## Production-diff gate (§66)

`git diff --name-only a392c49e..HEAD` at the time of closure must
show only `.factory/**` changes. Any `src/**`, `integration/**`,
`extensions/**`, or `packages/**` change → HALT_SCOPE_VIOLATION.

## Working-tree closure (§67)

`git status --short` after final commit must be empty (or only show
untracked files explicitly allowed). No `swamp-char01/`,
`swamp-char-rest01/`, `deno-cache/`, `home/` residue permitted.

## Evidence packet conservation (§68)

`manifest.json`, `RESULT.md`, `FAILURE-INVENTORY.md`,
`normalized/summary.txt` must agree on runner counts, failure counts,
cluster counts, classification counts, verdict, DOGFOOD_READY,
subject SHA, Deno version.

## Commit discipline (§69)

One Factory-only commit preferred:

```
factory(swamp): characterize remaining test-suite failures
```

Trailers:

```
Factory-ACT: SWAMP-CHARACTERIZE-REST01
Factory-State: CLOSED
Factory-Verdict: <actual verdict>
Factory-Subject: a392c49e1c899fbbbbf39bf84d73a8308c048eb6
Factory-Dogfood-Ready: <true|false>
```

Do not modify or amend accepted production repair commits.

## Expected successful outcome (§73)

A perfectly good result is fully classified, every current failure
is in a canonical bucket, no UNRESOLVED remain, and the verdict
reflects the actual mix (often MIXED).
