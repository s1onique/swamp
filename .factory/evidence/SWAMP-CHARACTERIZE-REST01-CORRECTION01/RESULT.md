# RESULT — SWAMP-CHARACTERIZE-REST01-CORRECTION01

## Verdict

  REMAINING_FAILURE_SURFACE_MIXED  (unchanged from parent ACT)

  but with corrected cluster inventory:

    CLUSTER-01  ENVIRONMENTAL             FALSIFIED_BY_CONTROL
    CLUSTER-02  UNRESOLVED (was ENV)      OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD
    CLUSTER-03  TEST_CONTRACT_AMBIGUITY   REPRODUCED_REPEATEDLY
                (was PROJECT_DEFECT)

  DOGFOOD_READY = false
  reason: unresolved count is 1 (gate requires 0)
  note: this is causally earned via the corrected CLUSTER-02
        classification; the prior ACT's "false" assertion lacked
        such mechanical justification.

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6
  (factory(swamp): qualify ANSI diagnostic normalization)

## What the parent ACT got right

  - primary run captured naturally,
  - 33 failures enumerated,
  - 3 clusters identified,
  - CLUSTER-01 falsified by control,
  - CLUSTER-03 reproducibly deterministic (3/3),
  - no production code changes,
  - scratch/cache discipline,
  - all files hashed, manifest verified.

## What the parent ACT got wrong

  1. CLUSTER-02 evidence label "REPRODUCED_REPEATEDLY" was an
     overclaim. The honest label is
     "OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD". The parent ACT
     counted three "reproductions" but they were all the same
     non-reproduction (isolated runs all green).

  2. CLUSTER-03 framing "30 ms child lifetime + 100 ms abort
     delay too tight on arm64" was a symptom-level description
     of what is actually a contract-level problem: the fixture
     creates scenario B (abort after natural exit) but the
     assertion enforces scenario A (abort while alive).

  3. DOGFOOD_READY=false was asserted while every enumerated
     gate passed. The corrected CLUSTER-02 (now UNRESOLVED)
     provides the missing mechanical reason for false.

## Jobs executed (correction ACT)

  Job 1 (CLUSTER-02 controls):
    10 reproduction runs across DENO_JOBS=1/2/default,
    isolated, neighborhood co-run (cluster-01+remote_exec),
    worker-class co-run, full integration/ co-run.
    All green except one tangential cluster-01 fluke.

  Job 2 (CLUSTER-03 reframe):
    Source-level analysis of test code (read-only).
    Two non-equivalent invariants identified.
    Repair direction re-named to TERMINAL-RACE.

  Job 3 (DOGFOOD_READY derivation):
    Mechanical re-derivation against corrected inventory.
    False, by virtue of unresolved > 0.

## Recommended next ACTs (one of two, depending on bisect outcome)

  - SWAMP-REMOTE-PARALLEL-INTERFERENCE01
    Bisect full suite for CLUSTER-02 reproduction.

  - SWAMP-DOCTOR-TERMINAL-RACE01
    Resolve CLUSTER-03 contract ambiguity.

  After both, DOGFOOD_READY may be re-evaluated.

## Conservation holds (corrected)

  passed + failed + ignored = 12287 + 33 + 30 = 12350 = total
  classified sum              = 31 + 1 + 1 = 33 = runner_failed

## Negative claims

  NO_PRODUCTION_CODE_CHANGED:      true
  NO_REPO_LOCAL_SCRATCH:           true
  NATURAL_COMPLETION:              true
  ALL_FAILURES_CLASSIFIED:         true (each in one of 3 categories)
  WORKING_TREE_CLEAN_AT_FINAL_COMMIT: pending (this commit)
  ACT_SCRATCH_CLEANED_AT_CLOSURE:  pending (this commit)
