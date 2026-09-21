# ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION08
## Make Closure Attestation Acyclic

**Author:** Cline
**Date:** 2026-09-21
**Subject:** `a392c49e1c899fbbbbf39bf84d73a8308c048eb6` (unchanged; no
source-tree change)
**Status:** CLOSED (factory-only)
**Supersedes:** CORRECTION07 (which closed the *terminal verifier
self-future pass promotion* but stopped one layer short of the
underlying fixed-point problem).

## 0. Preamble

CORRECTION07 closed the four immediate epistemic defects (D1-D4) of
CORRECTION06: the terminal verifier now emits `DEFERRED` instead of
self-promoting `PASS`, the post-execution verifier is the sole
authority on the eight deferred properties, the terminal-run identity
hash is now sensitive to verifier + stdout + stderr + exitcode, and
bundle freshness is checked file-by-file.

CORRECTION07's committed bundle reports `8/8 PASS` for the post-execution
verifier. Operationally, this is the most trustworthy closure yet
produced by this packet.

However, an audit of CORRECTION07 surfaced a **structural** defect that
CORRECTION07 did not address — and cannot address by adding more
self-referential invariants. The defect is:

> **The closure architecture is cyclic.**

Every CORRECTION layer since CORRECTION02 has been trying to make a
Git commit authoritatively prove its own final identity. That has no
fixed point in content-addressed storage.

Concrete observations from the CORRECTION07 audit:

(R1) Patch hygiene fails the closure's own standard.
`git diff --check HEAD~1 HEAD` reports trailing whitespace in
`check_characterize_rest01_correction03.sh` line 1099 (a tab before
`\n`). This particular closure machinery explicitly cares about scoped
authored hygiene, and the final claim "clean" was already too strong.

(R2) The authoritative projections are still stale even though
`AUTHORITATIVE_PROJECTIONS_AGREE = PASS`. The CORRECTION07 sweep
recognizes a closed set of claim-position patterns; the stale fields
fall outside its extraction grammar:
  * POST-COMMIT-ATTESTATION.md line 32: `ATTESTATION_CONTAINER_COMMIT
    = 1e00ae0bbac05abe660da04bfa2efa051e628c6a` — that is the
    CORRECTION06 attestation, not D7. The pattern uses
    `attestation_commit_sha`, not `attestation_container_commit`.
  * normalized/summary.txt line 63: `ATTESTATION_COMMIT =
    2e3f00c85e651c5ea3a1d4abea8d7e77bdb443c3` — that SHA does not even
    exist in our history (it was a transient attempt during the
    CORRECTION06 cycle).
  * RESULT.md line 417-418 collapses Commit C and Commit D to the
    same SHA (both `fd8d3386...`), despite the live D7 being
    `3c7bfce0...`.

(R3) The post-execution verifier is not actually bound to the final
D7 state it claims to authorize. The committed
`post_execution/head.txt` reads `bf88136d45f2d7a9d7cee1a178629b72df6c7c88`
(the intermediate attestation commit produced before the post-exec
bundle was amended into D7). The post-exec verifier output itself
reports `GIT_DERIVED_HEAD_SHA=bf88136d...`. The operator summary
claims D7=`3c7bfce0...` and HEAD~1=C7=`fd8d3386...`, but the verifier
that produced the PASS verdict ran against `bf88136d...`, not `3c7bfce0...`.

(R1-R3) all point at the same root cause: the closure apparatus was
trying to make a Git commit contain authoritative proof of its own
final identity, which is structurally recursive.

## 1. The structural recursion problem

The current architecture:

```
D7 = "attestation commit"
D7 contains: postcommit/, terminal_run/, post_execution/, manifest.json,
              POST-COMMIT-ATTESTATION.md, normalized/summary.txt,
              RESULT.md, epic-board.md, the CORRECTION0{4,5,6,7} ACTs

post_execution/verifier.stdout inside D7 says "VERIFIER_RESULT=PASS"
post_execution/verifier.stdout says "GIT_DERIVED_HEAD_SHA=bf88136d..."

But D7's HEAD is 3c7bfce0. So D7 claims that a verifier run against
bf88136d authorized 3c7bfce0. That is a temporal gap the verifier
itself was honest about.
```

You cannot make `D verifies D` true with an ordinary Git commit if D
contains the verifier output about D, because **writing the output
changes D**.

## 2. The clean model: subject → evidence → attestation

```
C8 = immutable content/closure subject
     (the final closure state, after content + script fixes)

V  = verifier execution over C8's working tree at capture-time
     (run while HEAD = C8; outputs frozen as evidence in C8)

A8 = attestation commit
     A8 contains evidence about C8, AND exposes the static relations
     that verify C8's claims.
     A8 does NOT claim to verify itself.
```

Three roles, three commits:

| Role | Identifier | Knows about | Does NOT know about |
|---|---|---|---|
| Subject | C8 | Its own content + terminal_run/ (the capture-time verifier output) | The attestation commit |
| Attestor | A8 | C8's content + C8's tree + C8's terminal_run/ + post_execution/ (the post-exec verifier output) | Whether A8 itself satisfies A8's claims |
| External auditor | (out of band) | A8's content + C8's content | (full information) |

Authority claim from A8:

```
A8_ATTESTS = C8
VERIFIER_SUBJECT = C8
C8_RESULT = PASS    (proven by C8:terminal_run/verifier.stdout)
A8_RESULT = (not claimed)
```

A8 then exposes ONLY these static relations, derivable by any reader
of A8's tree:

(S1) `A8:evidence.subject == C8`            — explicit subject reference
(S2) `C8 is parent/ancestor of A8`          — topological, from `git merge-base --is-ancestor C8 A8`
(S3) `bundle hashes verify`                 — bundle hash inside C8 == re-derived from `git ls-tree C8:terminal_run/`
(S4) `verifier result over C8 == PASS`      — `git show C8:terminal_run/verifier.stdout` has `VERIFIER_RESULT=PASS`, `VERIFIER_FAIL=0`
(S5) `all projections inside A8 name C8 as the subject` — static string check; no SHA outside C8's chain (C8's parent, C8 itself, A8) appears in a current-state claim position

Note carefully: **none of these relations require that A8's verifier
output be re-evaluated against A8**. The verifier output committed in
A8's `post_execution/` directory is informational — it lets a reader
verify that the same eight properties that were deferred by the
terminal verifier are also bound by an independent machinery that reads
ONLY committed evidence. But the verdict authority for "C8 satisfied
policy P" is the terminal_run/ bundle inside C8, evaluated against C8
(by an external reader running `git show C8:terminal_run/verifier.stdout`).
The post-execution machinery in A8 simply provides defense-in-depth
and audit trail; it does not have authority over C8.

If a reader wants to verify A8 as container integrity (i.e. that A8 is
a faithful recording of C8's claims), they need an external layer:
signed tag, CI provenance, transparency log, or another commit that
references A8's digest without containing A8. This ACT does not
attempt to construct that external layer — it simply stops pretending
that A8 can authoritatively verify A8.

This mirrors the SLSA provenance model: attestations reference
subject digests; the subject does not embed the attestation.

## 3. What changes in CORRECTION08

### 3.1 Verifier script

* Add `--subject C8_SHA` argument (required for `--mode post-exec`).
  The verifier refuses to run in `--mode post-exec` without an explicit
  subject SHA. This makes the recursion break mechanically explicit.
* `--mode post-exec --subject C8` evaluates the eight properties
  against **C8's tree** (read with `git ls-tree C8:...`), not against
  A8's tree. The post-exec bundle committed in A8 is treated as
  evidence A8 carries about C8's bundle, not as self-verification.
* Output line `VERIFIER_SUBJECT=<C8>` is emitted instead of
  `GIT_DERIVED_HEAD_SHA=<A8>` in post-exec mode.
* Output line `VERIFIER_RESULT_AT_SUBJECT=<PASS|FAIL>` is emitted instead
  of `VERIFIER_RESULT=PASS` for the post-exec verdict. The naming
  makes the acyclic scope explicit.
* The `AUTHORITATIVE_PROJECTIONS_AGREE` sweep is expanded to recognize
  the full set of current-state claim positions that have appeared in
  the projections across CORRECTION02-07: `Content commit`,
  `Commit C`, `Content_commit`, `content_commit_sha`,
  `CONTENT_COMMIT_SHA`, `Attestation commit`, `Commit D`,
  `Attestation_commit`, `attestation_commit_sha`,
  `ATTESTATION_COMMIT_SHA`, `ATTESTATION_CONTAINER_COMMIT`,
  `CURRENT_CONTENT_COMMIT`, `CURRENT_ATTESTATION_COMMIT`,
  `CONTENT_TREE_SHA`, `CONTENT_TREE`, `TERMINAL_RUN_ID`,
  `TERMINAL_BUNDLE_HASH`, `ATTESTATION_BINDING`, etc. The sweep also
  fires FAIL when a claim asserts `Commit D = Commit C` (the
  C-equals-D collapse observed in CORRECTION07's `RESULT.md`).
* Static relations S1-S5 above are emitted as new
  `STATIC_RELATION_S<N> = PASS|FAIL` machine lines so any downstream
  reader can verify the acyclic closure without re-running the
  verifier.

### 3.2 Manifest.json (committed in C8)

* Drop `terminal_run_id`, `terminal_bundle_hash` from manifest.json.
  Those values live in `terminal_run/manifest.txt`, which is committed
  inside C8's tree (immutable). The post-execution verifier (in A8)
  reads them from `terminal_run/manifest.txt` via `git show C8:terminal_run/manifest.txt`.
* Add `subject_commit: C8_SHA` and `attestor_commit: PENDING_AT_A8_COMMIT_TIME`.
* The five "current state" scalars (VERIFIER_RESULT, etc.) move to
  `terminal_run/manifest.txt` and become C8-anchored: they reflect
  the verifier output when run against C8's working tree, not against
  A8's tree.

### 3.3 POST-COMMIT-ATTESTATION.md (committed in C8)

* The "Authority" section is rewritten as: "This artifact lives in C8.
  It records the verifier output captured at C8's freeze time. A8
  (a descendant commit) contains the post-execution verifier bundle
  for cross-checking, but A8 does not authoritatively verify C8."
* All "current HEAD" claims are dropped. The artifact names C8 as
  the subject throughout. There is no concept of "this artifact
  attests itself."
* `ATTESTATION_CONTAINER_COMMIT` field is removed.

### 3.4 normalized/summary.txt (committed in C8)

* `CONTENT_COMMIT`, `ATTESTATION_COMMIT` are renamed to
  `SUBJECT_COMMIT` (the one true identifier) and
  `ATTESTOR_COMMIT` (recorded as PENDING until A8 exists; the post-exec
  verifier populates it during the A8 commit step but it does NOT
  claim A8 = PASS).
* `ATTESTATION_COMMIT_PROJECTIONS_AGREE` is removed (it conflated
  content and attestation commits). Replaced by
  `STATIC_RELATION_S5_PASS_COUNT` and
  `STATIC_RELATION_S5_FAIL_COUNT` which are derived from S5.

### 3.5 RESULT.md (committed in C8)

* The historical blocks (`CORRECTION04 closure`, `CORRECTION05 closure`,
  `CORRECTION06 closure`, `CORRECTION07 closure`) are explicitly
  marked as **historical references to prior cycles** and never as
  current state.
* The current-state "Commit C / Commit D" block is replaced by:
  ```
  Subject commit (C8):                       <C8 SHA>
  Attestor commit (A8):                      <A8 SHA, populated at A8 commit time>
  Content tree:                              git rev-parse C8^{tree}
  Terminal run executed:                     TRUE (terminal_run/ committed in C8)
  Terminal bundle hash:                      sha256("BUNDLE_V1\n" + lex-ordered C8:terminal_run/ file bytes)
  Terminal run id:                           sha256("TV_RUN_V2\n" + 7 versioned fields)
  Post-execution verifier (informational):    post_execution/verifier.stdout says
                                              VERIFIER_RESULT_AT_SUBJECT=PASS, but is NOT the
                                              authority on C8. Authority on C8 is
                                              C8:terminal_run/verifier.stdout.
  ```

### 3.6 epic-board.md (committed in C8)

* The CORRECTION04-07 rows remain as historical records (they document
  what each cycle did and what the live SUBJECT_COMMIT was at the end
  of each cycle).
* A new CORRECTION08 row records the acyclic attestation architecture
  and the static relations S1-S5 as the closure criteria for this
  cycle.
* The previously claimed `CURRENT_CONTENT_COMMIT` field is removed.
  The board's purpose is to track **what each cycle produced**; the
  current subject is identified by `git rev-parse HEAD~1` (since the
  live `HEAD` is always A8 in this architecture; the subject is the
  parent).

### 3.7 terminal_run/ bundle (committed in C8)

* Add a `terminal_run/manifest.txt` file that captures the verifier
  output scalars (TERMINAL_RUN_ID, TERMINAL_BUNDLE_HASH, VERIFIER_RESULT,
  VERIFIER_FAIL, etc.) in machine-readable form. This file is the
  authoritative source for those values.
* Add a `terminal_run/manifest.txt` entry to `build_raw_sha256.sh`'s
  exclusion list (it is evidence, not raw content).

### 3.8 freeze_terminal_run.sh and freeze_post_execution.sh

* `freeze_terminal_run.sh` runs while `git rev-parse HEAD == C8`.
  Verifies the invariant "HEAD before freeze == C8" before writing
  any evidence.
* `freeze_post_execution.sh` is called during the A8 commit step,
  AFTER C8 has been committed. It records the post-execution verifier
  output for cross-checking but does not claim authority over C8.

## 4. Commit pattern (acyclic)

Step 1: Working tree = C8 content + whitespace fix + corrected
  projections + corrected verifier script.

Step 2: `git add -A && git commit -m 'content of CORRECTION08 ...'`
  → produces commit `C8`. C8's tree contains the corrected
  projections, the corrected verifier, and **none of the
  post-execution bundle** (which lives in A8).

Step 3: `bash freeze_terminal_run.sh` (run from C8's checkout).
  → produces `terminal_run/` files in working tree.
  Verifies HEAD == C8 before writing.

Step 4: `git add -A && git commit --amend --no-edit`
  → folds the terminal_run/ files into C8, so C8 contains its own
  evidence. This is the SLSA-style "subject carries its own
  provenance" model. The terminal_run/ bundle inside C8 attests C8
  minus terminal_run/ (which is the content of C8 if you mentally
  remove terminal_run/). A reader who runs
  `git show C8:terminal_run/verifier.stdout` sees the verifier
  verdict against C8's content minus terminal_run/.

Step 5: Author the A8 commit. A8 = C8 + CORRECTION08 ACT +
  post_execution/ bundle. The post_execution/ bundle records the
  post-execution verifier running against C8 (via `git show C8:...`)
  and produces `VERIFIER_RESULT_AT_SUBJECT=PASS` for S1-S5.

Step 6: Verify the static relations S1-S5 hold from A8's tree by
  re-running the verifier with `--mode post-exec --subject C8`.

## 5. Static relations S1-S5 (must all PASS)

(S1) `A8:evidence.subject == C8`
  → checked via `grep -E 'SUBJECT_COMMIT' .factory/acts/.../CORRECTION08.md`
  → checked via `grep -E 'subject_commit' .factory/evidence/.../manifest.json`

(S2) `git merge-base --is-ancestor C8 A8` returns 0
  → checked via `git merge-base --is-ancestor $C8 $A8`

(S3) `bundle hash inside C8 == re-derived from git ls-tree C8:terminal_run/`
  → checked via the post-exec verifier running `--subject C8`

(S4) `git show C8:terminal_run/verifier.stdout` contains
  `VERIFIER_RESULT=PASS` and `VERIFIER_FAIL=0`
  → checked via the post-exec verifier running `--subject C8`

(S5) Every current-state SHA claim inside A8's projections (manifest.json,
  POST-COMMIT-ATTESTATION.md, RESULT.md, normalized/summary.txt,
  epic-board.md, the CORRECTION08 ACT itself) names C8 or a value
  derivable from C8 (C8's tree, C8's parent, terminal IDs derived
  from C8's terminal_run/). No projection asserts that A8 == the
  attested subject. No projection asserts that A8's HEAD is the
  subject. No projection asserts `Commit D = Commit C`.
  → checked by the expanded `AUTHORITATIVE_PROJECTIONS_AGREE` sweep

## 6. What this ACT does NOT do

* It does not attempt to construct the external layer (signing, CI
  provenance, transparency log) that would let A8 be authoritatively
  verified by an outside party. The audit machinery stops here; a
  reader who wants signed closure should layer that on top.
* It does not introduce new doctrine properties. The eleven existing
  properties still hold; CORRECTION08 simply renames and reframes
  property 10 (`post-execution authority` becomes
  `attestation-acyclicity`) and adds the five static relations S1-S5
  as **mechanical** derivable checks, not as new doctrine.
* It does not retroactively re-validate CORRECTION04-07 cycles. Those
  rows on the board remain as historical records of what was true at
  each cycle's freeze time.
* It does not change the source tree (`src/`, `integration/`,
  `extensions/`, `packages/`, `deno.json`, `deno.lock`).
* It does not produce `A8_RESULT=PASS`. A8 has no result, only
  relationships to C8.

## 7. Recommended next ACT

After CORRECTION08 closes, the audit machinery is acyclic. The next
substantive ACT is `SWAMP-REMOTE-PARALLEL-INTERFERENCE01`: bisect
CLUSTER-02 (the unknown-red RPC channel close) using Deno's
`--parallel` flag with `DENO_JOBS` control axis. That experiment is
the only remaining unknown-red blocker to `DOGFOOD_READY=true`.

Do not begin that ACT automatically. The audit cycle must close first.

## 8. Negative claims (all true)

  NO_PRODUCTION_CODE_CHANGED,
  NO_SELF_VERIFYING_COMMIT,
  NO_A8_RESULT_CLAIM,
  EXPANDED_PROJECTION_SWEEP,
  ACYCLIC_ATTESTATION_ARCHITECTURE,
  C8_IS_PARENT_OF_A8,
  C8_TERMINAL_RUN_VERIFIES_C8_MINUS_TERMINAL_RUN,
  POST_EXECUTION_VERIFIER_IN_A8_INFORMATIONAL_NOT_AUTHORITATIVE,
  PATCH_HYGIENE_RESTORED,
  STALE_PROJECTION_LITERALS_REMOVED,
  COMMIT_C_NOT_EQUAL_TO_COMMIT_D (asserted in projections).
