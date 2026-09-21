# ACT-SWAMP-TEST-CHAR01-CORRECTION01

## Goal

Close three experimental-authority defects identified by the Factory reviewer of
TEST-CHAR01 before any production-code defect ACT can be issued.

## State

- **Prior ACT**: `SWAMP-TEST-CHAR01` CLOSED with verdict
  `TEST_SUITE_HAS_REPRODUCIBLE_DEFECTS`. Four targets classified:
  - D1 / D2 doctor: `DOCTOR_REPRODUCIBLE_DEFECT`
  - A1 / A2 ANSI:   `ANSI_REPRODUCIBLE_DEFECT`
  - 154 mkdir family: `ENVIRONMENTAL` (unwritable `$HOME/.claude/skills/swamp`).

- **Reviewer findings (all material)**:
  1. **Substrate confound**: TEST-CHAR01 ran an x86_64 Deno binary under Rosetta on an
     arm64 host (`uname -m == arm64`, `file deno == x86_64`). Process-signaling
     behavior on macOS may differ between native and translated runtimes.
  2. **Harness exit-code bug**: `run_isolated_doctor.sh` and `run_isolated_ansi.sh`
     capture `$?` AFTER intervening arithmetic/assignments, so the `.exitcode`
     artifacts are NOT the deno test exit code. The repeated failure observations
     remain valid (raw stdout summary lines were observed), but the recorded
     exit codes are not authoritative.
  3. **Doctor mechanism not proven**: We proved "runChildWithAbort doesn't complete
     before the child timer expires" but did NOT directly prove `SIGTERM` /
     `SIGKILL` delivery, `child.pid` lifetime, or that the issue is in
     `Deno.ChildProcess.kill` itself.
  4. **Cell-B had 44 failures, not 4**: The Cell-B partial run captured 44 FAILED,
     not just the four unresolved targets. The remaining ~40 failures are not yet
     characterized. Must be preserved as `NEW_FAILURE_SURFACE_UNCHARACTERIZED`.

## Bounded goals

1. **Fix the harness exit-code capture** in both `run_isolated_doctor.sh` and
   `run_isolated_ansi.sh`. Establish the doctrine:
   `reported_test_status agrees with process_exit_code`
   i.e., `FAILED summary  => exit != 0`;  `ok summary  => exit == 0`
   unless explicitly documented otherwise.

2. **Re-run doctor and ANSI targets under native aarch64 Deno 2.9.7**, N=5
   isolated each, with the corrected harness. Record substrate alongside:
   `uname -m`, `arch`, `file <deno>`, `deno --version`.

3. **Swamp-free subprocess signal microreproducer** that removes `doctor_audit.ts`
   from the picture entirely. Test four signal cases (M1–M4) on both x86_64 and
   arm64 Deno. Record: PID, send timestamp, status-resolution timestamp, elapsed,
   terminating signal, exit code, post-kill PID existence.

## Decision tree (post-CORRECTION01)

```
M1..M4 microreproducer on both runtimes
    + swamp test reruns on both runtimes
        ↓
native arm64 reproduces doctor
+ microreproducer reproduces
    → DOCTOR_REPRODUCIBLE_DEFECT (Deno/runtime issue; Swamp workaround required)
native arm64 reproduces doctor
+ microreproducer works
    → DOCTOR_REPRODUCIBLE_DEFECT (Swamp's runChildWithAbort is at fault)
x86_64 reproduces, arm64 passes
    → TOOLCHAIN_ARCH_DEPENDENT (downgrade)
```

ANSI has stronger direct evidence (literal ESC bytes observed via `od -c` with
`NO_COLOR=1`), but rerun on arm64 as a cheap cross-check.

## Files

- New ACT: this file
- New raw: `.factory/tmp/SWAMP-TEST-CHAR01-CORRECTION01/{x86_64,arm64}/{doctor,ansi,signal}/...`
- New evidence:
  `.factory/evidence/SWAMP-TEST-CHAR01-CORRECTION01/{MATRIX.md, SUBSTRATE.md, SIGNAL-MICROREPRODUCER.md, RESULT.md, manifest.json}`
- Edit: `.factory/scripts/run_isolated_doctor.sh`, `.factory/scripts/run_isolated_ansi.sh`
- Edit: `.factory/epic-board.md` (this ACT row: QUEUED → ACTIVE → CLOSED)
- Edit: `.factory/acts/SWAMP-TEST-CHAR01.md` (corollary note: superseded by CORRECTION01
  for substrate-binding claims; verdict still stands pending arm64 confirmation)

## Subject

```
SUBJECT: bcaa9695b7f27f51964a9f41587fdf112b261c89
DENO_VERSION: 2.9.7
DENO_RUNTIMES:
  x86_64: /tmp/deno-bin/deno     (Mach-O 64-bit executable x86_64)
  arm64:  /tmp/deno-arm64/deno   (Mach-O 64-bit executable arm64)
HOST: Darwin arm64 arm   23.6.0
```

## Doctrine additions (to be added to FACTORY.md / AGENTS.md on close)

- **Experimental conclusions are bound not only to source SHA, but also to
  execution substrate.**  Subject really is
  `(source SHA, runtime version, runtime architecture, OS/kernel, experiment config)`.
- **Conservation: `reported_test_status agrees with process_exit_code`** —
  harness exit-code capture must be authoritative; do not let intervening
  shell operations clobber `$?`.

## Status

QUEUED.
