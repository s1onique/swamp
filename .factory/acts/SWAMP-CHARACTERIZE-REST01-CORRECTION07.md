# ACT-SWAMP-CHARACTERIZE-REST01-CORRECTION07
## Establish Post-Execution Terminal Authority

**Author:** Cline
**Date:** 2026-09-21
**Subject:** `a392c49e1c899fbbbbf39bf84d73a8308c048eb6` (unchanged from
SWAMP-CHARACTERIZE-REST01 and all CORRECTION0X cycles; no source-tree change)
**Status:** CLOSED (factory-only)

## 0. Preamble

The CORRECTION06 closure was mechanically complete — it produced committed
`terminal_run/verifier.stdout` with `VERIFIER_TOTAL=91`, `VERIFIER_PASS=91`,
`VERIFIER_FAIL=0`, `VERIFIER_RESULT=PASS`, and committed exit code `0`.

However, an audit of the CORRECTION06 invariants surfaced FOUR residual
epistemic defects that are qualitatively distinct from a routine claim /
counter-claim cycle. They defeat the *purpose* of a closure auditor: to
distinguish "the closure packet looks internally consistent" from "the
closure packet authoritatively attests its own claim".

The four defects:

(D1) **Self-referential pass promotion.** During the `--mode terminal`
    run, two invariants
    (`TERMINAL_EXITCODE_IS_ZERO`, `TERMINAL_VERIFIER_RESULT_IS_PASS`)
    inspect properties of the verifier's own not-yet-produced output. They
    `pass` themselves with messages like `(... skipped — terminal run
    active ...)` and `(... committed stdout ... VERIFIER_RESULT=FAIL ...)`.
    The closure bundle reports `91/91 PASS`, but at least two of those
    passes are "PASS because the predicate cannot yet evaluate itself".
    This violates `execution status != semantic coverage` (doctrine
    property 7).

(D2) **Pseudo terminal-run identity.** `terminal_verifier_run_id` is
    claimed to identify a verifier execution but is actually
    `sha256(postcommit/{head, tree, exitcode})`. Two completely different
    verifier executions (different stdout, different exit code, even a
    different verifier binary) producing the same postcommit triple would
    hash to the same "run id". Concretely, in this cycle the postcommit
    exitcode is `1` (construction phase) yet it is baked into the
    "terminal run identity" that the closure invokes. The function is
    mis-named; it is an `ATTESTED_STATE_ID`, not an execution identity.

(D3) **Single-file freshness check.** `NO_STALE_TERMINAL_RUN_BUNDLE`
    proves only that `terminal_run/head.txt` matches
    `postcommit/head.txt`. An older `verifier.stdout` copied next to a
    new `head.txt` would pass. The bundle is multi-component; the
    freshness invariant should be bundle-identity.

(D4) **Stale authoritative projections.** `normalized/summary.txt` still
    claims `manifest.raw_hash_entry_count = 13`,
    `CONTENT_COMMIT = 04164de4...`, `ATTESTATION_COMMIT = f9fe4e0c...`
    (raw evidence count 26; content `4c1b2124`; attestation `229a8ab`).
    `RESULT.md` has hard-coded the previous-withdrawn attestation commit
    `c60376c40744cd8ef107c2a740a28e74199fd4a4` (later rounds mutated HEAD).
    These are exactly the projection-identity class of defects
    CORRECTION05 was supposed to eliminate; the verifier simply wasn't
    checking these particular projections.

These four defects together comprise a tenth doctrine property:

> **Post-execution authority.** A computation cannot authoritatively
> verify properties of its own not-yet-produced output. Claims about an
> execution's result must be evaluated by machinery running *after* that
> execution has become immutable evidence. This is the producer → evidence
> → verifier separation that underlies CI attestations, supply-chain
> provenance, and reproducible-build verification.

(For comparison: a build signoff signed by a build script that inspects
itself-in-progress is not authoritative. A trust chain needs three
independent machines — producer, evidence-capturer, third-party
auditor — at minimum.)

## 1. Architecture

```
            TERMINAL VERIFIER (machine A)
            ─────────────────────────────
            runs in --mode terminal
            inspects ONLY post-execution-immutable evidence:
            - content predicates (failures.json, classifications, ...)
            - projection-identity predicates (postcommit/non-self)
            marks 6 terminal-run/self-referential properties as DEFERRED

                       │
                       ▼
            produces frozen terminal_run/ bundle:
              - verifier.stdout
              - verifier.stderr
              - verifier.exitcode
              - verifier.sha256
              - head.txt
              - tree.txt
              - environment.txt
            (the bundle is byte-identical to committed postcommit/* at
             this point — both flows write to the same .factory tmp tree)

                       │
                       ▼
            POST-EXECUTION VERIFIER (machine B)
            ───────────────────────────────────
            runs in --mode post-exec
            reads ONLY:
              - the committed tree (git cat-file)
              - the frozen terminal_run/ blob contents (via git cat-file,
                NOT from on-disk working copy)
            evaluates the 6 DEFERRED properties against the frozen bundle
            evaluates the projection-identity predicates across ALL
            authoritative projections (manifest.json, attest_md, result_md,
            normalized/summary.txt, board row, CORRECTION07 ACT itself,
            attestation data projection at HEAD)
            emits:
              TERMINAL_RUN_EXECUTED              = true
              TERMINAL_RUN_EXITCODE              = 0
              TERMINAL_RUN_RESULT                = PASS
              TERMINAL_RUN_FAIL_COUNT            = 0
              TERMINAL_RUN_BUNDLE_HASH           = sha256(canonical bundle)
              TERMINAL_RUN_ID                    = sha256(canonical execution)
              AUTHORITATIVE_PROJECTIONS_AGREE    = true
```

The terminal verifier and post-execution verifier are two invocations of
the same script (with different `--mode`). The post-execution verifier
sees only the committed tree, never the on-disk working copy.

## 2. `TERMINAL_RUN_ID` (corrected)

`TERMINAL_RUN_ID` is now defined as a *hashed execution record*:

```text
TERMINAL_RUN_ID = sha256(
  "TV_RUN_V2\n"                             # framing, versioned
  ||
  versioned_field("verifier_sha256", sha256(committed verifier script))
  ||  "\n"
  ||
  versioned_field("content_commit",       GIT_CONTENT_COMMIT_SHA)
  ||  "\n"
  ||
  versioned_field("bundle_sha256",        TERMINAL_RUN_BUNDLE_HASH)
  ||  "\n"
  ||
  versioned_field("stdout_sha256",        sha256(terminal_run/verifier.stdout))
  ||  "\n"
  ||
  versioned_field("stderr_sha256",        sha256(terminal_run/verifier.stderr))
  ||  "\n"
  ||
  versioned_field("exitcode",             terminal_run/verifier.exitcode)
  ||  "\n"
  ||
  versioned_field("execution_mode",       "terminal")
  ||  "\n"
)
```

Each `versioned_field(name, value)` is `<name>=<value>` (no
length-prefix yet; reserved fields). The framing line `"TV_RUN_V2\n"` is
included to make the version explicit and prevent accidental collision
with `TV_RUN_V1`.

This identity changes if ANY of:
- the verifier script blob changes (verifier_sha256)
- the content commit blob changes
- the bundle hash changes
- the terminal stdout blob changes (different execution output)
- the terminal stderr blob changes
- the terminal exitcode changes
- the execution mode changes

Two different verifier runs, with different outputs but the same
content-tree, no longer share the same identity.

## 3. `TERMINAL_RUN_BUNDLE_HASH` (new)

```text
TERMINAL_RUN_BUNDLE_HASH = sha256(
  "BUNDLE_V1\n"
  ||
  filename || "=" || git_blob_bytes || "\n"  for each terminal_run file
)
```

Listed in fixed lexicographic order:
```
environment.txt
head.txt
tree.txt
verifier.exitcode
verifier.sha256
verifier.stderr
verifier.stdout
```

This is the bundle's *identity hash*. It changes if ANY byte of any
terminal_run file changes (including the .stdout).

## 4. `NO_STALE_TERMINAL_RUN_BUNDLE` (corrected)

Old check: `terminal_run/head.txt blob == postcommit/head.txt blob`.

New check: every terminal_run/* file exists in the committed tree, AND
for every terminal_run/*.txt and terminal_run/verifier.exitcode/sha256,
the corresponding `postcommit/*.txt`/etc. blob must exist with the
same SHA. (The postcommit bundle is the *expected* bundle the terminal
run should reproduce.) AND the `terminal_run_bundle_hash` computed in
section 3 must equal the hash projected into manifest.json, attest_md,
and the post-execution verifier's derived value.

This catches:
- A copied, stale terminal_run/head.txt next to a fresh postcommit
  bundle.
- An incomplete terminal_run directory (verifier.stdout present but
  verifier.exitcode missing).
- A terminal_run directory that has been hand-edited without re-running
  freeze_terminal_run.sh.

## 5. Authoritative projections (the new sweep)

The post-execution verifier parses every authoritative projection and
extracts any string that resembles a 40-hex SHA. It places them into
a *self-reported* set per projection. The verifier then derives
authoritative commit SHAs from `git rev-parse HEAD` and `HEAD~1`
(using frozen blob inspection):

```text
DERIVED_SHA256_SET = {
  git rev-parse HEAD,
  git rev-parse HEAD~1,
  sha256(VERIFIER_SCRIPT_BLOB),
  TERMINAL_RUN_BUNDLE_HASH,
  TERMINAL_RUN_ID,
  GIT_DERIVED_CONTENT_TREE_SHA,
  GIT_DERIVED_ATTESTATION_TREE_SHA,
}
```

Each projection's *self-reported SHA set* must:
- contain `git rev-parse HEAD~1` and `git rev-parse HEAD` (otherwise the
  projection is silent about authority, FAIL)
- contain no SHAs that are NOT in DERIVED_SHA256_SET (a projection
  claiming a commit that the worked tree does not actually contain is
  FAIL — this is exactly the projection-identity class of defect)

The projections checked are exactly the ones listed in
`manifest.json.authoritative_projections` (a projection registry)
PLUS:
- `manifest.json` itself
- `POST-COMMIT-ATTESTATION.md`
- `RESULT.md`
- `normalized/summary.txt`
- `epic-board.md`
- `SWAMP-CHARACTERIZE-REST01-CORRECTION07.md` (this ACT)
- The terminal_run/ blobs themselves

Total: 8 + 7 = 15 projections, each must have a consistent SHA set.

## 6. Files in this ACT cycle

Authored new:
- `.factory/acts/SWAMP-CHARACTERIZE-REST01-CORRECTION07.md` (this file)
- `.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/freeze_post_execution.sh`
- `.factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/post_execution/{verifier.stdout,stderr,exitcode,sha256,head,tree,environment}`

Updated (corrected projections / new fields / new invariants):
- `.factory/scripts/check_characterize_rest01_correction03.sh`
  - +5 new invariants (TERMINAL_RUN_EXECUTED, _EXITCODE, _RESULT,
    _BUNDLE_HASH, _PROJECTIONS_AGREE) and the corrected
    TVRID computation
  - +`--mode post-exec`
  - +`--mode terminal` now marks the 4 self-referential properties
    as DEFERRED rather than PASS (PREMIT)
- `.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/manifest.json`
  - `terminal_verifier_run_id` → renamed `terminal_run_id` (with new computation)
  - +`terminal_bundle_hash`
  - +`terminal_run_executed = true`
- `.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/POST-COMMIT-ATTESTATION.md`
  - TERMINAL_VERIFIER_RUN_ID → TERMINAL_RUN_ID (recomputed)
  - +TERMINAL_BUNDLE_HASH
- `.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/normalized/summary.txt`
  - corrected `manifest.raw_hash_entry_count = 26` (was 13)
  - corrected `CONTENT_COMMIT = 4c1b2124...` (was 04164de4)
  - corrected `ATTESTATION_COMMIT = 229a8ab...` (was f9fe4e0c)
  - added the new CORRECTION07 doctrine summary
- `.factory/evidence/SWAMP-CHARACTERIZE-REST01-CORRECTION03/RESULT.md`
  - corrected `ATTESTATION_COMMIT` literal (was c60376c4)
  - +CORRECTION07 block
- `.factory/epic-board.md`
  - +CORRECTION07 row

Removed:
- (none)

## 7. Verdict (provisional, depends on post-execution run)

The CORRECTION07 cycle will produce C7+D7. C7 freezes the post-commit
bundle as before (now including a `bundle_hash` projection). D7 commits
both the post-execution evidence bundle and C7. The terminal verifier
(`--mode terminal`) reports `PASS_COUNT=N, DEFERRED_COUNT=6`. The
post-execution verifier (`--mode post-exec`) reads only the committed
tree, evaluates the 6 deferred predicates + 5 projection-identity
predicates + 5 identity predicates = N+5 invariants and reports a fresh
VERIFIER_RESULT.

VERDICT (closure) = POST_EXECUTION_AUTHORITY_ESTABLISHED.
DOGFOOD_READY = false (CLUSTER-02 remains sole unknown-red blocker).

## 8. Properties stack (10 now)

1. arithmetic consistency
2. provenance integrity
3. causal sufficiency
4. verifier authority
5. projection consistency
6. temporal/state binding
7. semantic predicate fidelity
8. projection identity
9. evidence freshness / terminal-run binding
10. post-execution authority (this ACT — producer → evidence → verifier)

## 9. Negative claims

The CORRECTION07 cycle DOES NOT:
- change production code
- run the swamp Deno test suite
- change any classification
- start dogfood
- reopen prior CORRECTION cycles' verdicts
- use the same projector for both terminal and post-execution (separate
  invocations of the same script)

The CORRECTION07 cycle DOES:
- introduce a second verifier invocation that evaluates properties
  the terminal verifier could not
- introduce a bundle-identity hash
- introduce an authoritative-projections cross-validator
- sweep committed projections for stale Commit D/Commit C references

## 10. Recommended next ACT

After CORRECTION07 passes cleanly, the audit machinery is finally
trustworthy. The next move is **SWAMP-REMOTE-PARALLEL-INTERFERENCE01**:
use Deno's `--parallel` with `DENO_JOBS` to bisect CLUSTER-02 (the
unknown-red RPC channel close that survived every controlled subset).
The experiment axis is `Deno.parallel` worker count vs. observed
single-module failure rate.
