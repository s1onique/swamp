# SWAMP-CHARACTERIZE-REST01-CORRECTION05 — Projection Identity Consistency

## Verdict

PROJECTION_IDENTITY_CONSISTENCY_RESTORED

## Subject

`a392c49e1c899fbbbbf39bf84d73a8308c048eb6` (same source tree as
CORRECTION02..CORRECTION04 — no new reproduction experiment).

## Scope

`.factory/**` only. **No reproduction of failures.** **No classification
changes.** **No production code changes** (zero files in `src/`,
`integration/`, `extensions/`, `packages/`, `deno.json`, `deno.lock`).

## Defects closed

The CORRECTION04 closure packet, while passing the four CORRECTION04
invariants, still carried three concrete projection/identity contradictions
that survived into the committed tree:

1. **P1 — Commit identity contradiction.** Operator summary had
   `Commit D = f9fe4e0c...` but committed `RESULT.md` and
   `POST-COMMIT-ATTESTATION.md` contained `Commit D = 9b542d55...`
   (an intermediate amend that was itself superseded by the final
   `RESULT.md` append + re-amend). One authoritative projection cannot
   claim two different heads.

2. **P2 — Raw evidence cardinality contradiction.** Operator summary
   claimed "17 entries" (which was a different scalar entirely —
   the file size in lines, not the manifest count). The committed
   `raw-sha256.txt` actually has 13 entries, the verifier derived
   `RAW_SHA256_ENTRY_COUNT = 13`, but `manifest.json.raw_hash_entry_count`
   was `null`.

3. **P3 — Stale board projection.** Epic-board row for CORRECTION04
   still said `Content commit TBD; attestation commit (this row); raw
   entry count derived at runtime.` The content commit was known
   (`04164de4d28b4e14ed272b8b3e9feac83f3e9238`) but the active
   board line used the placeholder text.

These were not D-repairs 5-7. They are a new domain — **projection identity** —
where the closing moment of the cycle produces multiple committed
projections that disagree about the same scalar.

## Doctrine added

> **A derived scalar is not actually derived if one authoritative
> projection still stores `null`, `TBD`, or a contradictory literal.**

Doctrine properties enforced: now **eight** (CORRECTION05 adds "projection identity").

## Five new invariants (all PASS required)

The verifier emits these as independent PASS/FAIL lines; all five must pass:

- `ATTESTATION_COMMIT_PROJECTIONS_AGREE`
  `git cat-file blob COMMIT_D:.factory/evidence/.../POST-COMMIT-ATTESTATION.md`
  must contain the correct `CONTENT_COMMIT_SHA`; committed `RESULT.md`
  attestation-commit reference (when present) must equal `git rev-parse HEAD`;
  attestation must be an ancestor (or equal) of the named content commit.

- `CONTENT_COMMIT_PROJECTIONS_AGREE`
  `POST-COMMIT-ATTESTATION.md`'s `CONTENT_COMMIT_SHA` ==
  epic-board CORRECTION{04,05} row content commit SHA ==
  `git rev-parse HEAD~1`.

- `RAW_HASH_ENTRY_COUNT_PROJECTIONS_AGREE`
  `manifest.json.raw_hash_entry_count` ==
  `POST-COMMIT-ATTESTATION.md RAW_SHA256_ENTRY_COUNT` ==
  `RESULT.md RAW_SHA256_ENTRY_COUNT` ==
  runtime-derived `RAW_SHA256_ENTRY_COUNT` (from `wc -l
  <committed raw-sha256.txt>`).

- `BOARD_CONTENT_COMMIT_IS_NOT_PLACEHOLDER`
  Committed epic-board CORRECTION04/05 rows must NOT use
  `Content commit TBD` as the active projection. A 40-hex SHA must
  be present in the active row line.

- `MANIFEST_RAW_HASH_ENTRY_COUNT_IS_INTEGER`
  `manifest.json.raw_hash_entry_count` must be a non-null positive
  integer equal to the runtime-derived count.

## Authoritative scalar sources

| Scalar | Source |
| --- | --- |
| `git HEAD` (commit D) | `git rev-parse HEAD` |
| `content commit` (commit C) | `git rev-parse HEAD~1` |
| `content tree` | `git rev-parse HEAD~1^{tree}` |
| `attestation tree` | `git rev-parse HEAD^{tree}` |
| `raw sha256 entry count` | `wc -l <committed raw-sha256.txt>` |

Every projection in `.factory/evidence/.../`, `.factory/epic-board.md`,
and the verifier's deterministic output lines must equal these
git-derived values; otherwise the projection identity invariant fails.

## Verifier changes

- Default for `CONTENT_COMMIT_SHA` in postcommit mode is
  `git rev-parse HEAD~1` (was `PARENT_COMMIT`). Captures the
  post-CORRECTION03 chain correctly.
- Postcommit verifier now queries the COMMITTED POST-COMMIT-ATTESTATION,
  RESULT, manifest, and epic-board blobs via
  `git cat-file blob HEAD:<path>` and compares them to git-derived
  ground truth.
- Five `*_PROJECTIONS_AGREE` / `*_IS_NOT_PLACEHOLDER` / `*_IS_INTEGER`
  PASS/FAIL counters added.
- Twelve new deterministic projection lines emitted at the end:
  `GIT_DERIVED_*`, `ATTEST_MD_*`, `RESULT_MD_*`,
  `BOARD_CONTENT_COMMIT_SHA`, `MANIFEST_RAW_HASH_ENTRY_COUNT`.
- Expected-dirt exclusion list extended for CORRECTION05: ACT file,
  manifest, RESULT, normalized-summary, POST-COMMIT-ATTESTATION now
  counted as expected at capture time.

## Negative claims (all maintained)

`NO_PRODUCTION_CODE_CHANGED`, `NO_NEW_FAILURE_REPRODUCTION`,
`NO_CLASSIFICATION_CHANGE`, `NO_DOGFOOD_STARTED`,
`ATTESTATION_COMMIT_PROJECTIONS_AGREE`, `CONTENT_COMMIT_PROJECTIONS_AGREE`,
`RAW_HASH_ENTRY_COUNT_PROJECTIONS_AGREE`,
`BOARD_CONTENT_COMMIT_IS_NOT_PLACEHOLDER`,
`MANIFEST_RAW_HASH_ENTRY_COUNT_IS_INTEGER`.

## Expected post-commit verifier outcome (at Commit D)

- `VERIFIER_TOTAL` ≥ 82 (existing), +5 new identity invariants = ≥87.
- `VERIFIER_FAIL = 0`.
- All five new projection-identity invariants PASS.

## Dogfood gate

DOGFOOD_READY remains false. CLUSTER-02 (UNRESOLVED, cause_owner UNKNOWN,
evidence_strength OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD) remains the sole
unknown-red blocker.

## Recommended next ACT

`SWAMP-REMOTE-PARALLEL-INTERFERENCE01` (CLUSTER-02 bisect via
`deno test --parallel` + `DENO_JOBS` control). Approval gate now lifted —
the closure packet is internally consistent.

## Files in this cycle

- Authored: `SWAMP-CHARACTERIZE-REST01-CORRECTION05.md` (this file).
- Updated: `.factory/epic-board.md`, `.factory/evidence/.../manifest.json`,
  `.factory/evidence/.../POST-COMMIT-ATTESTATION.md`,
  `.factory/evidence/.../RESULT.md`,
  `.factory/scripts/check_characterize_rest01_correction03.sh`.
- `normalized/summary.txt` and the raw-evidence tree unchanged from
  CORRECTION04 (only filename-level dirt, not content).
