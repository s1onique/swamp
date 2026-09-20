# Factory Epic Board — Swamp

| ID               | State   | Purpose                                                  |
| ---------------- | ------- | -------------------------------------------------------- |
| SWAMP-BASELINE01                | CLOSED  | Establish pristine executable baseline and authority map; corrected by CORRECTION01 and CORRECTION02 |
| SWAMP-BASELINE01-CORRECTION01    | CLOSED  | Reconcile arithmetic, fix board state, fix patch hygiene — superseded by CORRECTION02 for telemetry classification |
| SWAMP-BASELINE01-CORRECTION02    | CLOSED  | Re-classify telemetry failures by observed signature; codify evidence-immutability doctrine |
| SWAMP-BASELINE01-CORRECTION03    | CLOSED  | Scope the evidence-hygiene verifier to the policy it enforces (policy == verifier scope == reported claim) |
| SWAMP-DOGFOOD01  | QUEUED  | Use Swamp externally as intended                         |
| SWAMP-ATTACK01   | QUEUED  | Adversarially falsify important guarantees               |
| SW-F01           | BACKLOG | Immutable/versioned Factory evidence experiment          |
| SW-F02           | BACKLOG | Deterministic attestation projection                     |
| SW-CM01          | BACKLOG | Harness/skill trigger evaluation                         |
| SW-CM04          | BACKLOG | ClineMM premature-handoff behavioral corpus              |
| SW-X01           | BACKLOG | Compile cognition away experiment                        |
| SW-M01           | BACKLOG | Typed workflow IR                                        |
| SW-M02           | BACKLOG | Gate-dominance proof                                     |

Notes on each ACT are deliberately short — only enough to preserve intent.
The baseline ACT (this one) carries the real plan in
`.factory/acts/SWAMP-BASELINE01.md`.

## Recommended ordering (operator's discretion)

1. `SWAMP-BASELINE01` (this ACT) — done; verdict is `BASELINE_ESTABLISHED_WITH_GAPS`.
2. *Pre-DOGFOOD work*: resolve the test-suite fragility (F1/F3 in
   FINDINGS.md) in a writable-`~/.claude/` environment. This is the
   highest-value pre-work because the upstream PR's claimed 12 288
   passes differs from this baseline's 12 128 passes; that gap must
   be explained before dogfooding on top of it.
3. `SWAMP-DOGFOOD01` — with the test suite trusted.
4. `SWAMP-ATTACK01` — once the baseline + dogfood establish what
   normal looks like.
5. `SW-F01`, `SW-F02` — Factory-specific extractions.
6. `SW-CM01`, `SW-CM04` — ClineMM-specific.
7. `SW-X01`, `SW-M01`, `SW-M02` — deeper evaluation work.

Do not auto-launch any of these after `SWAMP-BASELINE01` closes —
the ACT explicitly forbids it (`§25`).
