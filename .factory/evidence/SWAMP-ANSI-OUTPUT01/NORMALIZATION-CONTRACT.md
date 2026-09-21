# NORMALIZATION CONTRACT — ACT-SWAMP-ANSI-OUTPUT01

## Primary invariant

For every `QualityIssue` whose `check` is `"fmt"` or `"lint"`:

```
stripAnsiCode(issue.output) === issue.output
issue.output.includes("\x1b[") === false
issue.output.length > 0 when the underlying tool produced a failure
semanticContentTokensPresent(issue.output) === true   # meaningful text retained
```

## Boundary

The boundary function `normalizeExternalDiagnostic(output: string): string`
lives in `src/domain/extensions/extension_quality_checker.ts` and is the
single normalization site used by `checkExtensionQuality`. It is applied
to `stderr + stdout` after decoding, immediately before the result is
stored in `QualityIssue.output`.

It is NOT applied:
- to user-facing log output
- to internal Swamp audit renderers
- to other `check` kinds (`dynamic-import`, `version-drift`, …) whose
  output strings are constructed in TypeScript and never carry ANSI
- to extension manifest fields, error messages, or any other surface

## Empty-output behaviour

A failed subprocess that produces no output:

- before normalization: `(stderr + stdout).trim() === ""`
- after normalization: `normalizeExternalDiagnostic("") === ""`

A failed subprocess that produces ANSI-only output:

- before normalization: contains `ESC [` sequences
- after normalization: `""` (acceptable — no caller test fails on this)

## Stream ordering

`stderr + stdout` ordering is preserved. The ACT does not change it to
`stdout + stderr` and does not interleave. Temporal ordering between
piped streams is out of scope.

## Empty input

`normalizeExternalDiagnostic("") === ""`.

`normalizeExternalDiagnostic("\x1b[31m\x1b[0m\n") === ""`.

Both are acceptable representation behaviour and are asserted directly.

## What this contract does NOT guarantee

- That Deno, on every future version, will still emit ANSI. If Deno's
  behaviour changes so that `NO_COLOR=1` is honoured, the
  normalization becomes a no-op — still correct.
- That callers will preserve the diagnostic text through to the user.
  Callers may re-render or truncate; that is downstream.

## Mandatory predicates (verbatim, machine-checkable)

```
issue.check === "fmt"  OR  issue.check === "lint"
  =>
    !issue.output.includes("\x1b[")
    AND stripAnsiCode(issue.output) === issue.output
    AND issue.output.length > 0     // when tool produced any output
```

The existing tests `checkExtensionQuality: fmt output contains no ANSI
escape codes` and `checkExtensionQuality: lint output contains no ANSI
escape codes` express these predicates and are retained verbatim.

## Combined fixture

The test `checkExtensionQuality reports both fmt and lint issues
together` additionally asserts:

```
result.issues.filter(i => i.check === "fmt").length === 1
result.issues.filter(i => i.check === "lint").length === 1
```

Proves: normalization does not merge or hide issues.

## Semantic-content predicates (new, augmentation of existing tests)

```
fmt issue output includes "not formatted" and "model.ts"
lint issue output includes "ban-unused-ignore"
```

Proves: meaningful diagnostic content is preserved by normalization
(does not collapse to a useless empty/decorative-only string).
