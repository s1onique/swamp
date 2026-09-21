# ACT-SWAMP-TEST-CHAR01

**STATUS**: SUPERSEDED by `SWAMP-TEST-CHAR01-CORRECTION01` for substrate-binding claims.

This ACT's verdict (`TEST_SUITE_HAS_REPRODUCIBLE_DEFECTS`) was based on
x86_64-under-Rosetta Deno observations and missed the substrate confound.
CORRECTION01 reproduces all failures on native arm64 Deno and identifies
the actual causes:

- D1/D2 doctor: `ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL` (host macOS sandbox blocks kill)
- A1/A2 ANSI:   `DENO_BEHAVIOR_NO_COLOR_NOT_HONORED` (Deno 2.9.7 fmt/lint emit ANSI escapes)
- 154 mkdir family: `ENVIRONMENTAL` (unchanged)

See `.factory/evidence/SWAMP-TEST-CHAR01-CORRECTION01/RESULT.md` for the
authoritative corrected characterization.

---


**Mission**: Characterize the pristine Swamp test-suite failures observed by
`SWAMP-BASELINE01` and determine, with reproducible evidence, which failures
are caused by filesystem/home policy, dependency-cache state,
network/cache availability, parallel execution, TTY/color behavior,
real deterministic defects, or nondeterministic flake.

**Scope**: only `.factory/**`. No production source mutation.

This ACT inherits from the corrected baseline:

```
BASELINE_SUBJECT:    bcaa9695b7f27f51964a9f41587fdf112b261c89
ACT_HEAD (start):    20a5fcf694c9bcaf3d82349710f0339e1a63b1b4  (CORRECTION03)
UPSTREAM_HEAD:       bcaa9695b7f27f51964a9f41587fdf112b261c89
MERGE-BASE:          bcaa9695b7f27f51964a9f41587fdf112b261c89
no .factory-excluded files differ from BASELINE_SUBJECT
```

## Baseline observation (canonical, immutable)

```
12128 passed | 160 failed | 30 ignored

classification (from CORRECTION02):
  154 environmental — ~/.claude/skills/swamp mkdir PermissionDenied
    2 environmental — JSR manifest/cache failure
    4 genuine_or_flaky — unresolved
  160 total

unresolved:
  doctor_audit_test.ts:
    SIGTERM-respecting child ~30029 ms timeout
    SIGKILL escalation        ~30032 ms timeout
  extension_quality_checker_test.ts:
    fmt output contains no ANSI escape codes
    lint output contains no ANSI escape codes
```

## Doctrine

A passing rerun does not prove the original failure was environmental.
A failing rerun does not prove a production defect. Repeated outcomes plus
controlled-variable experiments are required.

Three-way invariant still binding:

```
policy == verifier scope == reported claim
```

Use `.factory/scripts/check_evidence_hygiene.sh` to produce all three.

## Toolchain

```
Deno:  deno 2.9.7 (stable, release, x86_64-apple-darwin)
       v8 15.0.245.2-rusty, typescript 6.0.3
Git:   git version per `git --version`
Host:  Darwin, darwin kernel
```

Deno binary path: `/tmp/deno-bin/deno` (the host does not have `deno` on
the default `PATH`; the Nix-managed `~/.nix-profile/bin` directory is
on `PATH` but is not present on disk, and `/usr/local/bin` and `~/bin`
are unwritable. The release binary is therefore stored in `/tmp/deno-bin/`,
which is local-only and survives only until reboot.)

## Canonical test command

```
SWAMP_NO_TELEMETRY=1 /tmp/deno-bin/deno test \
  --parallel \
  --unstable-bundle \
  --allow-read \
  --allow-write \
  --allow-env \
  --allow-run \
  --allow-net \
  --allow-sys \
  --allow-ffi
```

with `HOME`, `SWAMP_HOME`, `DENO_DIR` set externally per cell.

## Primary environment/cache matrix

| Cell | HOME                          | DENO_DIR                     | network | command |
|------|-------------------------------|------------------------------|---------|---------|
| A    | real user HOME                | existing baseline DENO cache | avail   | canonical |
| B    | synthetic writable temp HOME  | fresh empty temp DENO_DIR    | avail   | canonical |
| C    | synthetic writable temp HOME  | prewarmed from B              | avail   | canonical |
| D    | synthetic writable temp HOME  | prewarmed from B/C            | offline | canonical + `--cached-only` |

## Per-failure characterization targets

- doctor_audit_test.ts (2 SIGTERM/SIGKILL termination cases) — §11
- extension_quality_checker_test.ts (2 ANSI cases)             — §12
- telemetry_*_test.ts (2 JSR-cache cases)                       — §13 (controls)

## Required verdicts

For each unresolved target one of:

```
DOCTOR_REPRODUCIBLE_DEFECT
DOCTOR_LOAD_SENSITIVE_FLAKE
DOCTOR_ENVIRONMENT_DEPENDENT
DOCTOR_NOT_REPRODUCED
DOCTOR_INCONCLUSIVE

ANSI_REPRODUCIBLE_DEFECT
ANSI_TTY_DEPENDENT
ANSI_ENVIRONMENT_DEPENDENT
ANSI_PARALLELISM_DEPENDENT
ANSI_FLAKY
ANSI_NOT_REPRODUCED
ANSI_INCONCLUSIVE
```

## Primary verdict

```
TEST_SUITE_ENVIRONMENTALLY_EXPLAINED
TEST_SUITE_HAS_REPRODUCIBLE_DEFECTS
TEST_SUITE_FLAKY
TEST_SUITE_MIXED
TEST_SUITE_CHARACTERIZATION_INCONCLUSIVE
```

## Mechanical conservation

For every full-suite run:

```
passed + failed + ignored == total reported tests
sum(per_file_failures) == failed
```

For the four unresolved targets:

```
classified_targets == 4
```

unless verdict is explicitly `INCONCLUSIVE`.

## HALT conditions

production source changed | baseline raw evidence hash changed |
synthetic HOME leaked | cache state leaked across cells |
network/cache cannot be distinguished | raw capture failed |
test suite mutated source | parser violated conservation laws

## Recommended next ACT (exactly one)

Either `SWAMP-DOGFOOD01` if all failures are environmentally explained,
or `ACT-SWAMP-DOCTOR-SIGNAL01` / `ACT-SWAMP-ANSI-OUTPUT01` /
`ACT-SWAMP-DENO-CACHE01` / `ACT-SWAMP-SWAMP-HOME01` for any remaining defect.

# END ACT-SWAMP-TEST-CHAR01
