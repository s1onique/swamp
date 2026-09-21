# ACT-SWAMP-ANSI-OUTPUT01 — Plan & Outcome

## Mission (one-line)

Repair the extension quality-checker diagnostic contract so externally
produced ANSI terminal control sequences do not leak into Swamp-owned
`QualityIssue.output`.

## Root cause

`checkExtensionQuality()` in
`src/domain/extensions/extension_quality_checker.ts` runs `deno fmt --check`
and `deno lint` as child processes with `NO_COLOR=1` in the environment,
then concatenates `stderr + stdout`, trims, and stores in
`QualityIssue.output`.

Deno 2.9.7 emits ANSI escape sequences in failing `deno fmt --check` and
`deno lint` stderr despite `NO_COLOR=1 TERM=dumb piped non-TTY`. Deno's
own documentation states `NO_COLOR` causes the CLI to *attempt* to avoid
colour codes — best-effort, not guaranteed.

CAUSE_OWNER = `DEPENDENCY_BEHAVIOR`.
HANDLING_QUALITY (before) = `UNNORMALIZED`.

## Boundary design

Add `normalizeExternalDiagnostic(output: string): string` to the
production file. Apply it at the two producer sites (`fmt` failure,
`lint` failure) — the only places where external diagnostic bytes enter
a Swamp-owned data structure.

The helper uses `stripAnsiCode` from `@std/fmt/colors` (already in the
import map; 79+ existing import sites including
`src/domain/models/bundle.ts` which uses the same primitive in the
same shape).

The defence is layered: NO_COLOR=1 (best-effort request, preserved) +
normalizeExternalDiagnostic (guarantee, regardless of dependency
behaviour).

## Files changed

Production (2 files):
- `src/domain/extensions/extension_quality_checker.ts`
  - added `import { stripAnsiCode } from "@std/fmt/colors"`
  - added `export function normalizeExternalDiagnostic(output: string): string`
  - applied at fmt failure site and lint failure site
- `src/domain/extensions/extension_quality_checker_test.ts`
  - imported `normalizeExternalDiagnostic`, `stripAnsiCode`, `assertFalse`
  - strengthened existing `fmt` and `lint` ANSI tests (added
    `stripAnsiCode(output) === output` invariant + semantic content
    assertions)
  - strengthened existing combined-fmt/lint test (added issue count
    conservation + ANSI absence across all)
  - added 9 new direct-normalization unit tests (N1 plain, N2 colored,
    N2 compound, N3 multiline, N4 Unicode, N5 not-stripped,
    empty, ANSI-only, trim)

Factory (`factory` directory only):
- `.factory/epic-board.md` (board state)
- `.factory/acts/SWAMP-ANSI-OUTPUT01.md` (this file)
- `.factory/evidence/SWAMP-ANSI-OUTPUT01/` (authored packet)
- `.factory/tmp/SWAMP-ANSI-OUTPUT01/` (raw evidence)

Nothing else is modified. `deno.json`, `deno.lock`, AGENTS.md,
verification/**, infrastructure, CLI, and other extension code are
untouched. The standard-library import causes no lockfile change.

## RED → GREEN

RED captured against production code at `d21b7d2`:

```
deno test ... src/domain/extensions/extension_quality_checker_test.ts
  exit=1
  FAILED | 47 passed | 2 failed (6s)
  failing: fmt ANSI test, lint ANSI test
```

Dependency-behaviour evidence captured in
`.factory/tmp/SWAMP-ANSI-OUTPUT01/deno-control/`:
`deno fmt --check --no-color=1 --term=dumb` → 5 ESC bytes in stderr.
`deno lint --no-color=1 --term=dumb` (ban-unused-ignore) → 6 ESC bytes
in stderr.

GREEN captured after production fix:

```
deno test ... src/domain/extensions/extension_quality_checker_test.ts
  exit=0
  ok | 58 passed | 0 failed (6s)
```

Broader extension group:
```
ok | 129 passed | 0 failed (8s); exit=0
```

`deno check`, `deno lint`, `deno fmt --check` for the two production
files: all exit 0.

## Verdict

`ANSI_OUTPUT_NORMALIZATION_REPAIRED`.

## Recommended next ACT

Exactly one:

`ACT-SWAMP-CHARACTERIZE-REST01` — characterize any remaining wider
test-suite defects and address them in dedicated ACTs.
