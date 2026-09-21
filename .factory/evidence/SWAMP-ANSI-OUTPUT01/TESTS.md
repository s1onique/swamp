# TESTS — ACT-SWAMP-ANSI-OUTPUT01

All tests live in `src/domain/extensions/extension_quality_checker_test.ts`.
The production source lives in `src/domain/extensions/extension_quality_checker.ts`.

## A. RETAINED (existing) — must continue to pass after the fix

| # | Test name | What it asserts | Status before | Status after |
| - | --------- | --------------- | ------------- | ------------ |
| A1 | `checkExtensionQuality: fmt output contains no ANSI escape codes` | `issue.output.includes("\x1b[") === false` | **FAIL** (RED) | **PASS** |
| A2 | `checkExtensionQuality: lint output contains no ANSI escape codes` | `issue.output.includes("\x1b[") === false` | **FAIL** (RED) | **PASS** |
| A3 | `checkExtensionQuality reports both fmt and lint issues together` | both check kinds present | PASS | PASS (augmented) |

A1 and A2 are the authoritative contract tests. The assertions are
**not** weakened — `issue.output.includes("\x1b[") === false` is
unchanged.

## B. AUGMENTED — strengthened the existing contract

| # | Augmentation | Purpose |
| - | ------------ | ------- |
| B1 | A1 now also asserts `stripAnsiCode(fmtIssue.output) === fmtIssue.output` | Stronger invariant: stored output is already normalized |
| B2 | A1 now also asserts the output includes `"not formatted"` and `"model.ts"` | Semantic preservation: meaningful text retained |
| B3 | A2 now also asserts `stripAnsiCode(lintIssue.output) === lintIssue.output` | Stronger invariant |
| B4 | A2 now also asserts the output includes `"ban-unused-ignore"` | Semantic preservation |
| B5 | A3 now also asserts `result.issues.filter(i => i.check === "fmt").length === 1` and same for `"lint"` | Issue count conservation |
| B6 | A3 now also asserts `for every issue: !issue.output.includes("\x1b[")` | ANSI absent for all issues from the combined fixture |

## C. NEW (this ACT) — direct normalization primitive

| # | Test name | Primitive under test | Category |
| - | --------- | -------------------- | -------- |
| C1 | `normalizeExternalDiagnostic: removes SGR color sequences (RED, bold, reset)` | input `\x1b[31m...error: file is broken\x1b[0m\n` → output `"error: file is broken"` | N2 (coloured text) |
| C2 | `normalizeExternalDiagnostic: removes 256-color and compound SGR sequences` | input `\x1b[38;5;245m...\x1b[1m\x1b[31m...\x1b[0m` → output preserves `export const x=1;` | N2 (compound) |
| C3 | `normalizeExternalDiagnostic: preserves plain text after trim` | `"  simple plain diagnostic  \n"` → `"simple plain diagnostic"` | N1 (plain text) |
| C4 | `normalizeExternalDiagnostic: preserves multiline structure` | 3 lines + trailing empty → 3 lines, decoration removed | N3 (multiline) |
| C5 | `normalizeExternalDiagnostic: preserves Unicode diagnostic content` | Cyrillic + Greek in a diagnostic; length and content preserved | N4 (Unicode) |
| C6 | `normalizeExternalDiagnostic: does not strip ASCII that looks ANSI-ish` | `"[error] [31m ESC-like ordinary text..."` → unchanged | N5 (no accidental stripping) |
| C7 | `normalizeExternalDiagnostic: empty input yields empty output` | `""` → `""` | empty |
| C8 | `normalizeExternalDiagnostic: ANSI-only input collapses to empty` | `"\x1b[31m\x1b[0m\n"` → `""` | ANSI-only |
| C9 | `normalizeExternalDiagnostic: trims leading/trailing whitespace` | `"  \n\x1b[31mhello\x1b[0m\n  \n"` → `"hello"` | trim contract |

All C1–C9 are deterministic, fast (sub-millisecond to single-digit ms),
and do **not** invoke `deno fmt` / `deno lint`. They prove the
normalization primitive itself.

## D. Contract predicates used in tests

```typescript
issue.output.includes("\x1b[") === false           // primary
stripAnsiCode(issue.output) === issue.output       // stronger
result.issues.filter(i => i.check === "fmt").length === 1  // conservation
result.issues.filter(i => i.check === "lint").length === 1 // conservation
fmt output includes "not formatted" and "model.ts"  // semantic
lint output includes "ban-unused-ignore"            // semantic
```

## E. What tests do NOT assert

- Exact ANSI byte counts in raw dependency output (those vary by Deno
  version; only the dependency experiment captures them).
- Exact whitespace patterns in the diagnostic (formatter-stable, but
  not the contract).
- The exact rendered Swamp output to the user (downstream of
  `QualityIssue.output`; renderer-layer is not this ACT's scope).

## F. Regression group run for ACT §25

Run together (combined exit-code 0):

```
src/domain/extensions/extension_quality_checker_test.ts
src/domain/extensions/extension_collective_validator_test.ts
src/domain/extensions/extension_content_extractor_test.ts
src/libswamp/extensions/quality_test.ts
integration/extension_publish_visibility_test.ts
integration/extension_kind_sync_test.ts
```

Captured: `.factory/tmp/SWAMP-ANSI-OUTPUT01/regression/regression.stdout`
Exit: 0. Parsed summary: `ok | 129 passed | 0 failed (8s)`.

`extension_kind_sync_test.ts` is a compile-time-only test (asserted by
`deno check`); its 1 test appears in the count above.

## G. Focused regression checks (ACT §24)

| Check | Command | Exit |
| ----- | ------- | ---- |
| Type check | `deno check src/domain/extensions/extension_quality_checker.ts src/domain/extensions/extension_quality_checker_test.ts` | 0 |
| Lint | `deno lint src/domain/extensions/extension_quality_checker.ts src/domain/extensions/extension_quality_checker_test.ts` | 0 |
| Format | `deno fmt --check src/domain/extensions/extension_quality_checker.ts src/domain/extensions/extension_quality_checker_test.ts` | 0 |
| Focused test suite | `deno test ... src/domain/extensions/extension_quality_checker_test.ts` | 0 |

Captured under `.factory/tmp/SWAMP-ANSI-OUTPUT01/regression/`.
