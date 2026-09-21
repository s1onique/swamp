# DESIGN — ACT-SWAMP-ANSI-OUTPUT01

## Diagnosis

`checkExtensionQuality()` in
`src/domain/extensions/extension_quality_checker.ts` runs `deno fmt --check`
and `deno lint` as child processes, concatenates `stderr + stdout`, trims
it, and stores the result in `QualityIssue.output`.

Deno 2.9.7 emits ANSI escape sequences in both commands' stderr despite:

- `env: { ...baseEnv, NO_COLOR: "1" }` on the child process,
- `TERM=dumb` (typical CI),
- piped (non-TTY) stdout/stderr.

Deno's own documentation states `NO_COLOR` causes the CLI to *attempt* to
avoid colour codes — best-effort, not guaranteed. Swamp cannot rely on
that attempt.

## Doctrine applied

> Root cause and robustness responsibility are separate dimensions.

- CAUSE_OWNER = `DEPENDENCY_BEHAVIOR` (Deno emits ANSI despite NO_COLOR=1).
- HANDLING_QUALITY was `UNNORMALIZED`. After this ACT it is `ROBUST`.

Swamp does not patch Deno. Swamp owns the boundary where external
diagnostic bytes enter Swamp-owned data structures, and therefore owns
the contract that those data structures never carry ANSI decoration.

## Boundary design

A single ingestion helper, `normalizeExternalDiagnostic`, is the only
point where `stderr + stdout` becomes `QualityIssue.output`:

```
normalizeExternalDiagnostic(output: string): string {
  return stripAnsiCode(output).trim();
}
```

This applies only at the two producer sites (fmt + lint) inside
`checkExtensionQuality`. It is **not** applied globally to all Swamp
strings — preserving the existing audit/render path's use of colour for
internal Swamp diagnostics.

## Library choice

`stripAnsiCode` from `@std/fmt/colors` is preferred over a hand-rolled
regex:

- It is already a transitive target of this repo's import map
  (`"@std/fmt": "jsr:@std/fmt@^1.0.10"`); 79+ existing import sites
  use the module, including `src/domain/models/bundle.ts` which uses
  the same primitive in the same shape (`stripAnsiCode(rawDetails)`
  after `stderr + stdout`).
- It handles the broader ANSI escape set (CSI, OSC, etc.), not just
  SGR colour sequences — a `\x1b\[[0-9;]*m` regex would under-strip.
- No new dependency / lockfile / declaration is introduced. Verified by
  `git diff --stat deno.json deno.lock` showing no diff.

## Defensive layering

The defence is **both**:

1. `NO_COLOR=1` remains on the child process — best-effort request,
   unchanged from baseline.
2. `normalizeExternalDiagnostic` runs at the ingestion boundary —
   guarantee, regardless of dependency behaviour.

This is a layered defence, not a replacement. The two cooperate.

## Scope discipline

Production code changed only in:
- `src/domain/extensions/extension_quality_checker.ts` — added
  `normalizeExternalDiagnostic` and applied it at the two producer sites.
- `src/domain/extensions/extension_quality_checker_test.ts` — added
  stronger invariants on the existing two ANSI tests, added a new
  combined-fixture assertion of issue conservation, added 9 deterministic
  unit tests for the normalization primitive.

Nothing else is modified. No new files outside the two authorized
production files. No edits to `deno.json`, `deno.lock`, AGENTS.md,
verification/ scripts, or any other extension/infrastructure code.
