# SWAMP-CHARACTERIZE-REST01-CORRECTION06 — Bind Closure to Terminal Verifier Run

## Verdict

TERMINAL_RUN_BINDING_RESTORED

## Subject

`a392c49e1c899fbbbbf39bf84d73a8308c048eb6` (same source tree as
CORRECTION02..05 — no reproduction, no classification change).

## Scope

`.factory/**` only. **No reproduction of failures.** **No classification
changes.** **No production code changes.**

## Defect closed

The CORRECTION05 closure packet passed 87/87 verifier checks in
operator summary, but the COMMITTED `postcommit/verifier.stdout`
contained 88/13/FAIL with exitcode=1 — an earlier failed freeze
run. The committed authoritative evidence contradicted the closure
claim.

This was property 9: **Evidence freshness / terminal-run binding.**
The eight previous properties (arithmetic consistency, provenance
integrity, causal sufficiency, verifier authority, projection
consistency, temporal/state binding, semantic predicate fidelity,
projection identity) can all hold conceptually while the wrong
execution instance is frozen as authority.

## Doctrine added

> **When multiple verifier executions occur during closure
> construction, the committed authoritative evidence MUST correspond
> to the FINAL successful execution that authorizes closure, not an
> earlier failed execution.**

Doctrine properties enforced: now **nine** (CORRECTION06 adds
"evidence freshness / terminal-run binding").

## Four new invariants (all PASS required, postcommit only)

- `TERMINAL_EXITCODE_IS_ZERO`
  committed `postcommit/verifier.exitcode` == 0.

- `TERMINAL_VERIFIER_RESULT_IS_PASS`
  committed `postcommit/verifier.stdout` contains
  `VERIFIER_RESULT=PASS` and `VERIFIER_FAIL=0`.

- `TERMINAL_VERIFIER_RUN_ID_IS_BOUND`
  `manifest.terminal_verifier_run_id` ==
  `POST-COMMIT-ATTESTATION.md` `TERMINAL_VERIFIER_RUN_ID` ==
  `sha256(committed postcommit/{head.txt, tree.txt, verifier.exitcode})`.

- `NO_STALE_TERMINAL_RUN_BUNDLE`
  When `terminal_run/` is committed (C6+, optional), its `head.txt`
  blob SHA matches the committed `postcommit/head.txt` blob SHA.

## Mechanic

1. `freeze_postcommit.sh` captures the binary bundle (`head.txt`,
   `tree.txt`, `status.txt`, `environment.txt`, `verifier.sha256`,
   `verifier.stderr`, `verifier.exitcode`, `verifier.stdout`).
2. The postcommit bundles are committed (C6). They reference the
   content commit and trees, but the verifier stdout at C6 still
   reflects an earlier failed execution — that is acceptable as the
   construction-phase evidence.
3. A new `freeze_terminal_run.sh` runs the verifier ONCE MORE after
   C6 is committed. Because the committed bundles now match the
   on-disk state, the verifier sees a consistent tree and produces
   PASS output.
4. The terminal run produces an additional `terminal_run/` subdir
   with the binary evidence of the terminal successful execution.
5. `terminal_verifier_run_id` is the digest over the stable triple
   `{committed head.txt, tree.txt, verifier.exitcode}` and is
   projected into:
   - `.factory/evidence/.../manifest.json` (as
     `terminal_verifier_run_id`)
   - `.factory/evidence/.../POST-COMMIT-ATTESTATION.md` (as
     `TERMINAL_VERIFIER_RUN_ID = ...`)
6. D6 (the attestation commit) contains the terminal_run/ bundle.

## Negative control

`NO_STALE_TERMINAL_RUN_BUNDLE` invariant: substitute an older
`terminal_run/head.txt` blob whose SHA differs from the committed
postcommit/head.txt blob; the invariant must FAIL. Captured by the
predicate in invariant 9.

## Verdict (CORRECTION06 final)

TERMINAL_RUN_BINDING_RESTORED

DOGFOOD_READY = false. CLUSTER-02 (UNRESOLVED, cause_owner UNKNOWN,
evidence_strength OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD) remains the
sole unknown-red blocker.

## Recommended next ACT

`SWAMP-REMOTE-PARALLEL-INTERFERENCE01` (CLUSTER-02 bisect via
`deno test --parallel` + `DENO_JOBS`).

## Files in this cycle

Authored: `SWAMP-CHARACTERIZE-REST01-CORRECTION06.md` (this file).
Updated: `.factory/scripts/check_characterize_rest01_correction03.sh`
(9 invariants added), `.factory/epic-board.md`,
`.factory/evidence/.../manifest.json`,
`.factory/evidence/.../POST-COMMIT-ATTESTATION.md`,
`.factory/evidence/.../RESULT.md`,
`.factory/evidence/.../normalized/summary.txt`.
Added: `.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/freeze_terminal_run.sh`.
Frozen: `.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/terminal_run/`.
