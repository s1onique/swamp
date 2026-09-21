# PARALLELISM CHARACTERIZATION — SWAMP-TEST-CHAR01

## Hypothesis tested

```
H-DOCTOR-PARALLEL: failure probability for doctor_audit tests
                   increases under concurrent suite load.
```

## Evidence

The doctor tests are isolated runs (no `--parallel`):

```
isolated doctor (no --parallel, N=5):
  iter=1 61371 ms  FAILED 2/13
  iter=2 61463 ms  FAILED 2/13
  iter=3 61495 ms  FAILED 2/13
  iter=4 61498 ms  FAILED 2/13
  iter=5 61388 ms  FAILED 2/13
```

The same failures also appear in the full-suite run (Cell B.1)
with `--parallel`. The failures are NOT load-dependent — they
reproduce identically with or without parallel execution.

## Conclusion

```
H-DOCTOR-PARALLEL: FALSIFIED
```

Classification: `DOCTOR_REPRODUCIBLE_DEFECT` — not parallelism-related.

The DENO_JOBS control axis (DENO_JOBS=1, 2, default CPU) was not
exhaustively run because the parallelism hypothesis is already
falsified by the 5/5 isolated reproduction.
