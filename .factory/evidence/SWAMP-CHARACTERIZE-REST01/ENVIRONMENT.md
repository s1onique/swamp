# Environment record — ACT-SWAMP-CHARACTERIZE-REST01

## Substrate

| dimension | value |
| --------- | ----- |
| OS | Darwin MacBook-Pro-3.local 23.6.0 |
| kernel | Darwin arm64 (RELEASE_ARM64_T6031) |
| arch | arm64 |
| primary Deno | `/tmp/deno-arm64/deno` — Deno 2.9.7 (stable, release, aarch64-apple-darwin) — arm64 native |
| fallback Deno | `/tmp/deno-bin/deno` — Deno 2.9.7 (x86_64-apple-darwin) — Rosetta path (NOT used for characterization) |
| deno on PATH | **NO** — only `/usr/local/bin` `/usr/bin` etc.; the operator's deno binaries live at `/tmp/...` |
| network | available; JSR returns 200 |
| sandbox | ClineMM-mediated shell wrapper (timeout 600s per command) |

## Scratch state policy honored

```
NO_REPO_LOCAL_SCRATCH=true
EPHEMERAL_HOME_OUTSIDE_REPO=true (/tmp/swamp-char-rest01.ipyvth/home)
EPHEMERAL_DENO_DIR_OUTSIDE_REPO=true (/tmp/swamp-char-rest01.ipyvth/deno)
ACT_SCRATCH_CLEANED_AT_CLOSURE=true (see FINALIZATION section)
```

No `swamp-char01/`, `swamp-char-rest01/`, `deno-cache/`, or `home/`
directory was created inside the repository root.

## Cache prewarm

- Command: `deno cache --reload main.ts`
- Duration: 7 s
- Exit: 0
- Cache size after prewarm: 218 MB (`/tmp/swamp-char-rest01.ipyvth/deno`)
- Network during prewarm: available
- Subsequent `--cached-only` capability verification: PASSED
  (`.factory/scripts/parse_deno_test_result_test.ts` ran with
  `--cached-only`, 12 passed).
- Cache state classification: **VERIFIED_PREWARMED**.

## Raw substrate capture

```
=== UNAME ===
Darwin MacBook-Pro-3.local 23.6.0 Darwin Kernel Version 23.6.0: ...
arm64

=== DENO (primary native arm64) ===
/tmp/deno-arm64/deno: Mach-O 64-bit executable arm64
deno 2.9.7 (stable, release, aarch64-apple-darwin)
v8 15.0.245.2-rusty
typescript 6.0.3

=== DENO (x86_64 Rosetta fallback at /tmp/deno-bin/deno) ===
/tmp/deno-bin/deno: Mach-O 64-bit executable x86_64
deno 2.9.7 (stable, release, x86_64-apple-darwin)

=== ARCH ===
arm64

=== ENVIRONMENT (selected keys) ===
HOME=/Volumes/UserData/Users/chistyakov
LOGNAME=chistyakov
PATH=/Volumes/UserData/Users/chistyakov/.nix-profile/bin:...
TERM=screen-256color
TMPDIR=/private/var/folders/0g/mpt_55f524ndzxymkp20wjfc0000gn/T/clinemm-sandbox-temp-3Yv004

=== NETWORK ===
network=available
jsr_status=200
```

No secrets were captured.

## Substrate choice doctrine

This ACT explicitly chose **native arm64 Deno 2.9.7** as the
primary toolchain per ACT §4. The Rosetta x86_64 binary existed
from prior ACTs but was NOT used for this characterization.

## Comparison to upstream-baseline substrate

BASELINE01 (commit 4a2c946f, upstream merge-base) used the same
arm64 host with the x86_64 binary. SWAMP-CHARACTERIZE-REST01
deliberately used the native arm64 binary. The methodological
implication: SWAMP-CHARACTERIZE-REST01's failure counts and
classifications are **NOT directly numerically comparable** to
BASELINE01's counts (different substrate). However:
- SWAMP-ANSI-OUTPUT01's repairs remain verified under the new
  substrate (extension group: 129 passed | 0 failed, including
  previously-failing ANSI tests).
- The cluster-by-mechanism analysis is substrate-comparable:
  the SUBSTRATE-caused failures are explicitly identified.
