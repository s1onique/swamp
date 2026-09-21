# CORRECTION01 — Factory closure defects in ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01

## TL;DR

The reviewer accepted the production repair (`PRODUCTION_REPAIR =
ACCEPTED`) and identified three Factory closure defects
(`FACTORY_CLOSURE_PACKET = NEEDS_SMALL_CORRECTION`). This document
records the defect-by-defect evidence trail and their repairs.

**Verdict of correction**: `FACTORY_CLOSURE_PACKET_REPAIRED`.

## Defect 1 — Raw evidence not committed

**Symptom**: `git status` reported 13 untracked files under
`.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/**` even though the
ACT's RESULT.md claimed the directory was "immutable, hash-pinned".

**Repair**: commit all 13 raw evidence files in this ACT.

**Verification**: `.factory/scripts/check_signal_capability01_factory_closure.sh`
asserts `RAW_EVIDENCE_TRACKED=true` by comparing `git ls-files` count
against 13.

**Before fix**:

```
$ git ls-files .factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/ | wc -l
0
```

**After fix**:

```
$ git ls-files .factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/ | wc -l
13
```

## Defect 2 — Hash manifest was self-referential

**Symptom**: `raw-sha256.txt` previously listed a SHA-256 line for
itself:

```
89afe403d0941bf7a48d4b26def700b4681f919cce83bca587ef22a82c6ecf13  raw-sha256.txt
```

This line is a self-reference that cannot be verified (a file's
content cannot fix its own hash), and the value recorded there
(`89afe403…`) does not match the file's actual bytes (`613d635c…`).

**Repair**: regenerate `raw-sha256.txt` over all 12 raw evidence
files, **excluding `raw-sha256.txt` itself**. Add a header explaining
the manifest's scope. Verify every line against the working-tree
bytes.

**Before fix**:

```
$ grep raw-sha256.txt .factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/raw-sha256.txt
89afe403...  raw-sha256.txt   <-- self-reference
sha256sum: 613d635c...  actual
```

**After fix**:

```
$ grep raw-sha256.txt .factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/raw-sha256.txt
(no self-reference; manifest covers 12 other files)
```

**Verification**: `.factory/scripts/check_signal_capability01_factory_closure.sh`
asserts `RAW_HASH_MANIFEST_SELF_REFERENTIAL=false` and
`RAW_HASHES_VERIFY=true`.

## Defect 3 — Runner status conflated with semantic coverage

**Symptom**: The Deno runner reported `ok | 24 passed | 0 failed`
(both real-signal tests resolved to `ok` because the capability
gate short-circuits inside the test body). The closure text said
"22 passed, 2 capability-gated SKIP" — semantically useful but
**not** what the runner counts.

**Repair**: represent runner status and semantic coverage as
independent claims in RESULT.md, TESTS.md, CAPABILITY-MATRIX.md,
manifest.json, and normalized/summary.txt.

**Verification**: `.factory/scripts/check_signal_capability01_factory_closure.sh`
parses the Deno summary line from `portable-tests/final.log` and
asserts the runner-total conservation, the real-signal conservation,
and the portable-count conservation.

## Doctrine additions

1. **An authoritative evidence reference must resolve from the
   committed subject, not merely from the operator's working tree.**
2. **A coverage skip implemented inside an otherwise passing test is
   not a runner skip.** Record framework status and semantic coverage
   separately.
3. **A hash manifest must exclude itself.** Self-referential hashes
   are meaningless and trivially drift.


## Files added by this correction

- `.factory/acts/SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01.md`
- `.factory/scripts/check_signal_capability01_factory_closure.sh`
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/CORRECTION01.md`
  (this file)

## Files modified by this correction

- `.factory/tmp/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/raw-sha256.txt`
  (regenerated, excludes self)
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/RESULT.md`
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/TESTS.md`
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/CAPABILITY-MATRIX.md`
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/manifest.json`
- `.factory/evidence/SWAMP-DOCTOR-SIGNAL-CAPABILITY01/normalized/summary.txt`
- `.factory/epic-board.md`

## Production code

No production code changed. Production commits `4dc6c86e` and
`aec914a2` are preserved as-is.

## Verifier

```
$ bash .factory/scripts/check_signal_capability01_factory_closure.sh
=== ACT-SWAMP-DOCTOR-SIGNAL-CAPABILITY01-CORRECTION01 verifier ===

[1] Raw evidence tracked by git
PASS: RAW_EVIDENCE_TRACKED=true (13 files tracked)

[2] Hash manifest excludes itself
PASS: RAW_HASH_MANIFEST_SELF_REFERENTIAL=false (no self-hash line)

[3] Hash manifest verifies against working-tree bytes
PASS: RAW_HASHES_VERIFY=true (12 files re-hashed cleanly)

[4] Runner status conservation
PASS: RUNNER_TOTAL_CONSERVATION=true (passed=24 failed=0 ignored=0 total=24)

[5] Real-signal conservation
PASS: REAL_SIGNAL_TOTAL_CONSERVATION=true (executed=0 capability_unavailable=2 total=2)

[6] Portable tests executed
PASS: PORTABLE_TESTS_EXECUTED_EQUALS_EXPECTED=true (executed=22 expected=22)

[7] No production code changed in this correction ACT (vs prior ACT closure)
PASS: NO_PRODUCTION_CODE_CHANGED=true

[8] Production commit reachable from HEAD
PASS: PRODUCTION_COMMIT_REACHABLE=true (4dc6c86e is in HEAD's history)

[9] BASELINE01 raw SHA preserved
PASS: BASELINE01_RAW_SHA_PRESERVED=true (ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417)

=== Summary: 9 PASS, 0 FAIL ===
ALL_INVARIANTS_SATISFIED=true
```

## Recommended next ACT

`ACT-SWAMP-ANSI-OUTPUT01` (unchanged from prior recommendation).

---

# END CORRECTION01
