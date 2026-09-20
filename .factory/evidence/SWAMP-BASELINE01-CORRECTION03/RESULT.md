# RESULT — ACT-SWAMP-BASELINE01-CORRECTION03

**Verdict**: `EVIDENCE_HYGIENE_VERIFIER_SCOPED` (the verifier now
matches the doctrine; the doctrine, the verifier scope, and the
recorded claim are all in agreement).

**Subject**: `bcaa9695b7f27f51964a9f41587fdf112b261c89`
**Upstream subject**: same (fork local ACT).

---

## Verifier output (run at HEAD)

```
$ bash .factory/scripts/check_evidence_hygiene.sh HEAD~1..HEAD
WHOLE_RANGE_DIFF_CHECK=EXPECTED_FAIL_RAW_EVIDENCE
WHOLE_RANGE_WHITESPACE_ERRORS=1
WHOLE_RANGE_DETAIL:
  .factory/tmp/native-baseline/test.stdout:17650: new blank line at EOF.
AUTHORED_ARTIFACTS_DIFF_CHECK=PASS
AUTHORED_ARTIFACTS_CHECKED=9
RAW_EVIDENCE_SHA256=ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417
BASELINE01_REFERENCE_SHA256=ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417
RAW_EVIDENCE_SHA256_UNCHANGED=true
```

### Interpretation

- **Whole range check is `EXPECTED_FAIL_RAW_EVIDENCE`** — and that
  is success, not failure. The single whitespace error is the
  captured trailing blank line in `test.stdout`, which is part of
  the BASELINE01 raw evidence (byte-faithful to the original
  `deno task test` capture). Editing the file to make this check
  pass would *break* the evidence; restoring the original bytes
  *guarantees* the check fails on this file. Expected.

- **Authored-artifact check is `PASS`** — the doctrine of
  CORRECTION02 (raw evidence exempt; authored artifacts checked)
  is now matched by an actual scoped verifier. The 9 authored
  artifacts changed in `HEAD~1..HEAD` (the CORRECTION02 commit)
  all pass `git diff --check` individually.

- **Raw SHA256 unchanged from BASELINE01** — `ae420afe...` matches
  the BASELINE01 commit's blob SHA256.

## Three-way consistency

| layer | value |
|---|---|
| Policy (`.factory/evidence/SWAMP-BASELINE01/MANIFEST.md` evidence-hygiene section) | raw `.factory/tmp/**` exempt; `.factory/{evidence,acts}/**` + `epic-board.md` checked |
| Verifier scope (`.factory/scripts/check_evidence_hygiene.sh`) | excludes `.factory/tmp/**`; includes the rest |
| Reported claim | `AUTHORED_ARTIFACTS_DIFF_CHECK=PASS`, `WHOLE_RANGE_DIFF_CHECK=EXPECTED_FAIL_RAW_EVIDENCE` (expected, by design) |

Policy == verifier scope == reported claim. ✓

## Doctrinal addition

Added to `.factory/evidence/SWAMP-BASELINE01/MANIFEST.md`:

> **A verifier must be scoped to the policy it claims to enforce.**
> Three-way invariant: policy == verifier scope == reported claim.
> Use `.factory/scripts/check_evidence_hygiene.sh` to produce all
> three.

## Closure invariants

```
WHOLE_RANGE_DIFF_CHECK = EXPECTED_FAIL_RAW_EVIDENCE   ✓
AUTHORED_ARTIFACTS_DIFF_CHECK = PASS                 ✓
RAW_EVIDENCE_SHA256_UNCHANGED = true                 ✓ (ae420afe... == ae420afe...)
NO_RAW_EVIDENCE_MUTATED = true                       ✓
C1_CLASSIFICATION_UNCHANGED = true                   ✓ (154 mkdir + 2 JSR + 4 flaky = 160)
C2_BOARD_STATE_UNCHANGED = true                      ✓ (3 ACTs all CLOSED)
POLICY == VERIFIER_SCOPE == CLAIM                    ✓
```

## Negative claims (all true)

- `NO_SWAMP_PRODUCTION_CODE_CHANGED` — only `.factory/**` touched.
- `NO_RAW_EVIDENCE_MUTATED` — `test.stdout` SHA256 matches BASELINE01 capture.
- `NO_CLASSIFICATION_REOPEN` — C1 work from CORRECTION02 stands (154 mkdir + 2 JSR + 4 flaky = 160).
- `NO_BOARD_REOPEN` — C2 work from CORRECTION02 stands (all 3 ACTs CLOSED).
- `NO_FALSE_VERIFIER_CLAIM` — verifier is now scoped to the policy it claims to enforce.

## Operator-facing summary

```
ACT-SWAMP-BASELINE01-CORRECTION03

Verdict: EVIDENCE_HYGIENE_VERIFIER_SCOPED
Subject: bcaa9695b7f27f51964a9f41587fdf112b261c89

Three-way consistency now holds:
  policy      == verifier scope == reported claim

Reusable verifier created at:
  .factory/scripts/check_evidence_hygiene.sh

Recommendation: authorize SWAMP-TEST-CHAR01 immediately.
Matrix (carried from reviewer's proposal):
  A. real HOME + existing DENO_DIR cache
  B. synthetic HOME + fresh DENO_DIR
  C. synthetic HOME + prewarmed DENO_DIR
  D. synthetic HOME + --cached-only
```

`SWAMP-TEST-CHAR01` is now safe to authorize on top of this packet.

---

# END RESULT — ACT-SWAMP-BASELINE01-CORRECTION03
