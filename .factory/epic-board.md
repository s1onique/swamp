# Factory Epic Board — Swamp

| ID               | State   | Purpose                                                  |
| ---------------- | ------- | -------------------------------------------------------- |
| SWAMP-BASELINE01                | CLOSED  | Establish pristine executable baseline and authority map; corrected by CORRECTION01 and CORRECTION02 |
| SWAMP-BASELINE01-CORRECTION01    | CLOSED  | Reconcile arithmetic, fix board state, fix patch hygiene — superseded by CORRECTION02 for telemetry classification |
| SWAMP-BASELINE01-CORRECTION02    | CLOSED  | Re-classify telemetry failures by observed signature; codify evidence-immutability doctrine |
| SWAMP-BASELINE01-CORRECTION03    | CLOSED  | Scope the evidence-hygiene verifier to the policy it enforces (policy == verifier scope == reported claim) |
| SWAMP-TEST-CHAR01                | CLOSED  | Characterize test-suite failures via 4-cell cache × HOME matrix. Verdict: TEST_SUITE_HAS_REPRODUCIBLE_DEFECTS. 2 doctor + 2 ANSI defects all reproducible. 154 mkdir family confirmed environmental. Substrate-bound — see CORRECTION01. |
| SWAMP-TEST-CHAR01-CORRECTION01    | CLOSED  | Fix harness exit-code capture (DONE), re-run doctor+ANSI on native arm64 (DONE), Swamp-free subprocess-signal microreproducer on x86_64+arm64 (DONE). Verdict: TEST_CHARACTERIZATION_CORRECTED_TO_SUBSTRATE_AND_DENO_BEHAVIOR. D1/D2 doctor reclassified to ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL. A1/A2 ANSI reclassified to DENO_BEHAVIOR_NO_COLOR_NOT_HONORED. |
| SWAMP-DOCTOR-SIGNAL-CAPABILITY01  | CLOSED  | Make `runChildWithAbort` capability-aware and fail-explicit. Verdict: SIGNAL_CAPABILITY_HANDLING_REPAIRED. Added `ChildSignalDeliveryError` + `SignalAttempt` discriminated outcome + `_signalSender` test seam + capability probe. Portable tests T1-T8 deterministic; real-signal tests capability-gated. Denied-signal latency: 5285 ms → 32-114 ms. Substrate defect preserved (CAUSE_OWNER=SUBSTRATE, HANDLING_QUALITY=ROBUST). |
| SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01 | CLOSED | Repair 3 Factory closure defects. Verdict: FACTORY_CLOSURE_PACKET_REPAIRED. (1) Commit 13 raw evidence files (was untracked). (2) Regenerate `raw-sha256.txt` excluding itself (was self-referential). (3) Split runner status (24 passed / 0 failed / 0 ignored) from semantic coverage (22 portable executed + 0 real-signal executed + 2 capability-unavailable). No production code changed. Verifier: `.factory/scripts/check_signal_capability01_factory_closure.sh` — 9/9 invariants PASS. |
| SWAMP-ANSI-OUTPUT01                 | CLOSED  | Verdict: ANSI_OUTPUT_NORMALIZATION_REPAIRED. Cause owner DEPENDENCY_BEHAVIOR (Deno emits ANSI despite NO_COLOR=1); handling quality went from UNNORMALIZED → ROBUST. Added `normalizeExternalDiagnostic` (uses `@std/fmt/colors` `stripAnsiCode`, already in import map) at the two producer sites (fmt failure, lint failure); NO_COLOR=1 preserved as best-effort request. Test file went 47 passed + 2 failed → 58 passed + 0 failed; broader extension group 129 passed + 0 failed. deno check / lint / fmt --check all exit 0. Production diff = 2 files only (`extension_quality_checker.ts` + `extension_quality_checker_test.ts`); no deno.json / deno.lock / AGENTS.md / verification changes. Raw evidence 37 files hashed + verified. |
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
