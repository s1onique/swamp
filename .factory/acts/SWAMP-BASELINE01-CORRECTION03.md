# ACT-SWAMP-BASELINE01-CORRECTION03

**Scope**: only `.factory/**`. No production source mutation.

**Why this exists.** A Factory reviewer identified a single
remaining **verifier-scope** contradiction in the CORRECTION02 packet:

> The doctrine codified by CORRECTION02 says raw `.factory/tmp/**`
> evidence is exempt from `git diff --check`. But the recorded
> verification command was an unscoped `git diff --check HEAD~1..HEAD`,
> which by definition checks *every* file in the range — including
> the immutable raw evidence — and therefore *must* report the
> `test.stdout` blank-line-at-EOF that is, doctrinally, expected and
> correct.

The CORRECTION02 RESULT recorded "git diff --check … (empty)" as
evidence of `authored_artifacts_git_diff_check == PASS`. That command
is not scoped to authored artifacts. It checks raw evidence too. So
the recorded verification **command** does not match the
**doctrine** it claims to verify. That is exactly the authority
mismatch Factory exists to prevent:

```
policy:     raw evidence exempt from whitespace hygiene
verifier:   checks raw evidence anyway
claim:      verifier passed
```

If policy, verifier, and claim disagree, the evidence packet is not
authoritative. This ACT resolves that contradiction by:

1. Codifying a deterministic scoped verifier (`.factory/scripts/check_evidence_hygiene.sh`)
   that applies `git diff --check` only to authored artifacts, and
   classifies raw-evidence whitespace as an **expected** (and therefore
   non-failing) result.
2. Re-recording the verification as two distinct claims:
   `WHOLE_RANGE_DIFF_CHECK = EXPECTED_FAIL_RAW_EVIDENCE`
   and `AUTHORED_ARTIFACTS_DIFF_CHECK = PASS`.
3. Adding a doctrine line: **A verifier must be scoped to the policy
   it claims to enforce.**
4. Re-confirming the raw SHA256 is unchanged from BASELINE01 capture
   (`ae420afe...`) and no raw evidence was mutated.

This ACT does **not** reopen the C1 classification work (which the
reviewer affirmed is now coherent) or the C2 board work (all three
ACTs already show CLOSED).

---

## 1. Codify the scoped verifier

`.factory/scripts/check_evidence_hygiene.sh`:

```bash
#!/usr/bin/env bash
# Scoped evidence-hygiene check.
#
# Policy (codified by CORRECTION02):
#   .factory/tmp/**                     -> raw evidence, immutable, exempt
#   .factory/evidence/**                -> authored, hygiene-checked
#   .factory/evidence/**/normalized/**  -> authored derivative, hygiene-checked
#   .factory/acts/**                    -> authored, hygiene-checked
#   .factory/epic-board.md              -> authored, hygiene-checked
#
# This script checks the authored subset only and reports raw-evidence
# whitespace as EXPECTED_FAIL_RAW_EVIDENCE (not an error).

set -u

RANGE="${1:-HEAD~1..HEAD}"

# Whole-range check (raw evidence included).
WHOLE=$(git diff --check "$RANGE" 2>&1 || true)

# Authored-artifact check (raw evidence excluded).
AUTHORED_FILES=$(git diff --name-only "$RANGE" \
  | grep '^\.factory/' \
  | grep -v '^\.factory/tmp/' || true)

AUTHORED_VIOLATIONS=""
if [ -n "$AUTHORED_FILES" ]; then
  AUTHORED_VIOLATIONS=$(echo "$AUTHORED_FILES" \
    | xargs -I{} git diff --check "$RANGE" -- {} 2>&1 || true)
fi

# Raw SHA256 invariants (raw evidence must not have drifted).
RAW_SHA=$(sha256sum .factory/tmp/native-baseline/test.stdout 2>/dev/null \
  | awk '{print $1}')
BASELINE01_SHA=$(git show 4a2c946f:.factory/tmp/native-baseline/test.stdout \
  | sha256sum | awk '{print $1}')

# Output.
echo "WHOLE_RANGE_DIFF_CHECK=$(if [ -z "$WHOLE" ]; then echo "PASS"; else echo "EXPECTED_FAIL_RAW_EVIDENCE"; fi)"
echo "WHOLE_RANGE_WHITESPACE_ERRORS=$(printf '%s\n' "$WHOLE" | grep -c '^' || true)"
if [ -n "$WHOLE" ]; then
  echo "WHOLE_RANGE_DETAIL:"
  printf '%s\n' "$WHOLE" | sed 's/^/  /'
fi
echo "AUTHORED_ARTIFACTS_DIFF_CHECK=$(if [ -z "$AUTHORED_VIOLATIONS" ]; then echo "PASS"; else echo "FAIL"; fi)"
echo "AUTHORED_ARTIFACTS_CHECKED=$(echo "$AUTHORED_FILES" | grep -c '^' || echo 0)"
if [ -n "$AUTHORED_VIOLATIONS" ]; then
  echo "AUTHORED_ARTIFACTS_DETAIL:"
  printf '%s\n' "$AUTHORED_VIOLATIONS" | sed 's/^/  /'
fi
echo "RAW_EVIDENCE_SHA256=$RAW_SHA"
echo "BASELINE01_REFERENCE_SHA256=$BASELINE01_SHA"
echo "RAW_EVIDENCE_SHA256_UNCHANGED=$(if [ "$RAW_SHA" = "$BASELINE01_SHA" ]; then echo "true"; else echo "false"; fi)"
```

---

## 2. Expected output of the verifier at this ACT's final commit

```
WHOLE_RANGE_DIFF_CHECK=EXPECTED_FAIL_RAW_EVIDENCE
WHOLE_RANGE_WHITESPACE_ERRORS=1
WHOLE_RANGE_DETAIL:
  .factory/tmp/native-baseline/test.stdout:17650: new blank line at EOF.
AUTHORED_ARTIFACTS_DIFF_CHECK=PASS
AUTHORED_ARTIFACTS_CHECKED=10
RAW_EVIDENCE_SHA256=ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417
BASELINE01_REFERENCE_SHA256=ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417
RAW_EVIDENCE_SHA256_UNCHANGED=true
```

The whole-range `EXPECTED_FAIL_RAW_EVIDENCE` is **success**, not
failure: it confirms that the raw evidence is byte-faithful to the
original capture (and therefore contains the original captured
whitespace, exactly as the BASELINE01 commit left it).

---

## 3. Doctrine additions

Add to `.factory/evidence/SWAMP-BASELINE01/MANIFEST.md` evidence
hygiene section:

> **A verifier must be scoped to the policy it claims to enforce.**
> Three-way invariant: policy == verifier scope == reported claim.
> Use `.factory/scripts/check_evidence_hygiene.sh` to produce all
> three.

---

## 4. Required closure invariants

| invariant | assertion |
|---|---|
| `WHOLE_RANGE_DIFF_CHECK = EXPECTED_FAIL_RAW_EVIDENCE` | yes |
| `AUTHORED_ARTIFACTS_DIFF_CHECK = PASS` | yes |
| `RAW_EVIDENCE_SHA256_UNCHANGED = true` | yes |
| `NO_RAW_EVIDENCE_MUTATED = true` | yes |
| `C1_CLASSIFICATION_UNCHANGED` | yes (154 mkdir + 2 JSR + 4 flaky = 160) |
| `C2_BOARD_STATE_UNCHANGED` | yes (3 ACTs all CLOSED) |
| `POLICY == VERIFIER_SCOPE == CLAIM` | yes (all three on `.factory/{evidence,acts}/**` ∪ `epic-board.md`) |

---

## 5. Negative claims

- `NO_SWAMP_PRODUCTION_CODE_CHANGED` — only `.factory/**` touched.
- `NO_RAW_EVIDENCE_MUTATED` — `test.stdout` SHA256 matches BASELINE01 capture.
- `NO_CLASSIFICATION_REOPEN` — C1 work from CORRECTION02 stands.
- `NO_BOARD_REOPEN` — C2 work from CORRECTION02 stands.
- `NO_FALSE_VERIFIER_CLAIM` — verifier is now scoped to the policy.

---

## 6. After CORRECTION03 closes: SWAMP-TEST-CHAR01

Now safe to authorize. The reviewer proposed a stronger matrix than
my earlier "writable HOME" suggestion. Carry into TEST-CHAR01:

```
A. real HOME + existing DENO_DIR cache       (baseline re-run)
B. synthetic HOME + fresh DENO_DIR           (no PermissionDenied, no cache)
C. synthetic HOME + prewarmed DENO_DIR       (cache warm)
D. synthetic HOME + --cached-only            (force network failure → see what breaks)
```

For each of the 4 unclassified failures:

```
doctor_audit (SIGTERM/SIGKILL):
  isolated x20 (each test alone)
  full-suite x5 (with --parallel)

extension_quality_checker (fmt/lint ANSI):
  isolated x20
  TTY vs non-TTY
  full-suite x5

telemetry_* (now expected to PASS in any of A/B/C):
  verify they pass when cache is fresh
```

`SWAMP-TEST-CHAR01` will be the next ACT after this one closes.

---

# END ACT-SWAMP-BASELINE01-CORRECTION03
