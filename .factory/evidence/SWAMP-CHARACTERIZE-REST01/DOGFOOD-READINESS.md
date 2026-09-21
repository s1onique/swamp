# Dogfood-readiness decision

## Required projections (§42)

- NATURAL_COMPLETION=true
- runner failure inventory is complete: FAILURE-INVENTORY.md, 33 rows
- unresolved failures == 0 (no row carries UNRESOLVED)
- every current failure is classified (33 rows → 33 classifications)
- every project defect has a bounded follow-up ACT ID

## Decision

```
DOGFOOD_READY = false
```

## Why false despite zero UNRESOLVED

§42 sets gates so that even with `unresolved == 0`, the ACT may
set DOGFOOD_READY=false if:

- the project defect (CLUSTER-03) does not have a bounded
  follow-up ACT (it does — `SWAMP-DOCTOR-TIMING01`, suggested);
  OR
- a failure undermines a DOGFOOD01 mechanism we intend to dogfood.

The ACT's CLUSTER-03 is a NEW failure mode introduced by
SWAMP-DOCTOR-SIGNAL-CAPABILITY01 (production commit 4dc6c86e).
It is a PORTABLE test (no real-signal capability gate), so it
runs in every substrate. The fact that it fails on arm64 native
Deno 2.9.7 indicates the test's timing assumption was substrate-
specific (probably tuned for the x86_64 Rosetta binary used
during development of that ACT).

This ACT does not repair the test (per §45 — production-code
changes are forbidden). And §44 requires a bounded follow-up
ACT to be proposed for every PROJECT_DEFECT. The follow-up is
named `SWAMP-DOCTOR-PORTABLE-TIMING01` and would specifically:

1. Tighten the abort delay or the child lifetime so the
   `calls.length === 1` assertion holds on every substrate.
2. Add a per-substrate timing parameter to doctor_audit_test.

The ACT does not propose running `SWAMP-DOGFOOD01` until either:

(a) the project defect is repaired, OR
(b) a deliberate decision is taken to dogfood despite the
    test-suite fragility.

## Blockers list

| ID | blocker | mitigation |
| -- | ------- | ---------- |
| CLUSTER-03 | new project defect from a recently-accepted repair | propose `SWAMP-DOCTOR-PORTABLE-TIMING01` |
| CLUSTER-01 | substrate PATH gap (cosmetic for this ACT) | not a project blocker; the substrate would not have this gap in production CI or on a developer machine |
| CLUSTER-02 | parallel-load-induced RPC-channel close | not a project blocker in isolation; would block only if DOGFOOD01 enrolls remote workers under full-suite load |

## Recommended next ACT (§70)

`SWAMP-DOCTOR-PORTABLE-TIMING01` — repair the timing-edge in
`doctor_audit_test.ts` so the PORTABLE terminal-race test
holds across substrates. If approved and run successfully,
`SWAMP-DOGFOOD01` becomes the natural follow-up.
