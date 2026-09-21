# ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01

## Goal

Repair three Factory closure defects in the ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01
evidence packet. No production code changes. Production commit
`4dc6c86e` is preserved as-is.

The reviewer accepted the production repair
(`PRODUCTION_REPAIR = ACCEPTED`) and classified the closure packet as
`FACTORY_CLOSURE_PACKET = NEEDS_SMALL_CORRECTION`.

## State

- **Prior ACTs**: SWAMP-BASELINE01 (CLOSED), SWAMP-TEST-CHAR01 (CLOSED),
  SWAMP-TEST-CHAR01-CORRECTION01 (CLOSED),
  SWAMP-DOCTOR-SIGNAL-CAPABILITY01 (CLOSED).
- **SUBJECT** (unchanged): `bcaa9695b7f27f51964a9f41587fdf112b261c89`.
- **Production commit (preserved)**: `4dc6c86e`.
- **Factory closure commit (subject of correction)**:
  `aec914a21866e73eecf357bc289276f102fd80d0`.

## Defects to repair

### Defect 1 — Raw evidence not committed

Closure claimed `.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/**` is
the ACT's immutable raw evidence and hash-pinned. But on the
working tree, `git status` reports 13 untracked files under that
directory. A fresh checkout cannot reconstruct the ACT's evidence.

**Repair**: commit all 13 raw evidence files in this ACT so the
immutability claim is true from the committed tree.

### Defect 2 — Hash manifest is self-referential

`raw-sha256.txt` previously listed a SHA-256 line for itself
(`89afe403… raw-sha256.txt`). That line is a self-reference that
cannot be verified (you cannot fix a hash of a file whose content
includes its own hash), and the value recorded there
(`89afe403…`) does not match the file's actual current bytes
(`613d635c…`). The manifest is both meaningless and stale.

**Repair**: regenerate `raw-sha256.txt` over all 12 raw evidence
files, **excluding `raw-sha256.txt` itself**. Verify the manifest
re-hashes match the actual committed blobs.

### Defect 3 — Runner status conflated with semantic coverage

The Deno runner reported `ok | 24 passed | 0 failed` — both
real-signal tests showed `ok` to the runner even though their
bodies logged a `[capability-gated skip]` line. The closure text
called this "2 capability-gated SKIP", which is semantically
useful but **not** what the test runner counts.

**Repair**: represent both facts independently:

```text
RUNNER_STATUS:
  passed   = 24
  failed   = 0
  ignored  = 0

SEMANTIC_COVERAGE:
  portable_executed                   = 22
  portable_executed_expected          = 22
  real_signal_executed                = 0
  real_signal_capability_unavailable  = 2
  real_signal_total                   = 2
```

The capability-gated early-return is implemented as a code-level
skip with a logged reason, not as a Deno `t.step({ ignore: true })`
or `Deno.test({ ignore })`. That distinction is preserved as
doctrine.

## Scope

`.factory/**` only.

Production `src/**` is not modified. Verified by
`git diff --name-only <subject>..HEAD | grep -v '^.factory/'` ==
empty after this ACT.


## Files added

- `.factory/acts/SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01.md` (this file).
- `.factory/scripts/check_signal_capability01_factory_closure.sh`
  (verifier — asserts all invariants below).
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/CORRECTION01.md`
  (defect-by-defect evidence trail).

## Files modified

- `.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/raw-sha256.txt`
  (regenerated, excludes self).
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/RESULT.md`
  (runner status vs. semantic coverage split).
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/TESTS.md`
  (runner status vs. semantic coverage split).
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/CAPABILITY-MATRIX.md`
  (same split).
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/manifest.json`
  (same split; raw_evidence.tracked flag set true).
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/normalized/summary.txt`
  (same split).
- `.factory/epic-board.md` (row for this correction ACT).

## Files committed (raw evidence)

The following 13 raw evidence files are added by this ACT to make
the immutability claim true:

```
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/raw-sha256.txt            (regenerated)
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/capability-probe/probe.txt
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/portable-tests/final.exitcode
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/portable-tests/final.log
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/portable-tests/full-doctor.log
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/portable-tests/initial-run.log
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/portable-tests/run1.log
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/portable-tests/run2.log
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.exitcode
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.log
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.stderr
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.stdout
.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/red/red.substrate.txt
```

## Required verifier invariants

The new verifier `check_signal_capability01_factory_closure.sh`
asserts each of these and the closure is conditional on all PASS:

```text
RAW_EVIDENCE_TRACKED=true
RAW_HASH_MANIFEST_SELF_REFERENTIAL=false
RAW_HASHES_VERIFY=true

runner_passed  == 24
runner_failed  == 0
runner_ignored == 0
runner_total   == 24

real_signal_executed + real_signal_capability_unavailable
  == real_signal_total                       (== 2)

portable_tests_executed == portable_tests_expected   (== 22)

NO_PRODUCTION_CODE_CHANGED=true
```

## Doctrines added by this ACT

1. **An authoritative evidence reference must resolve from the
   committed subject, not merely from the operator's working tree.**
   If a hash manifest or an evidence pointer references a file,
   that file must be tracked by `git ls-files` in the same commit.

2. **A coverage skip implemented inside an otherwise passing test
   is not a runner skip.** Record framework status (what Deno's
   `ok | N passed | M failed` says) and semantic coverage (what the
   test body actually exercised) separately. The two are independent
   claims and must not be conflated.

3. **A hash manifest must exclude itself.** Self-referential hashes
   are meaningless (the file's content cannot fix its own hash) and
   trivially drift. Always hash the manifests' subjects, never the
   manifest itself.

## Closure invariants

```
RAW_EVIDENCE_TRACKED=true
RAW_HASH_MANIFEST_SELF_REFERENTIAL=false
RAW_HASHES_VERIFY=true
RUNNER_TOTAL_CONSERVATION=true
REAL_SIGNAL_TOTAL_CONSERVATION=true
PORTABLE_TESTS_EXECUTED_EQUALS_EXPECTED=true
NO_PRODUCTION_CODE_CHANGED=true
PRODUCTION_REPAIR_ACCEPTED=true         (carried from prior ACT)
NO_SUBSTRATE_FINGERPRINT_IN_PRODUCTION=true   (carried from prior ACT)
BASELINE01_RAW_SHA_PRESERVED=true       (carried from prior ACT)
```

---

# END ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01
