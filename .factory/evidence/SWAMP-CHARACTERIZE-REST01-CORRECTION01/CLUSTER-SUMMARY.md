# CLUSTER SUMMARY (corrected)

Primary run summary (unchanged):
  FAILED | 12287 passed (214 steps) | 33 failed | 30 ignored (1 step) (10m11s)
  NATURAL_COMPLETION=true, exit=1, subject=a392c49e

| Cluster | Count | Prior primary | Corrected primary | Prior evidence | Corrected evidence |
|---|---|---|---|---|---|
| CLUSTER-01 | 31 | ENVIRONMENTAL | ENVIRONMENTAL | FALSIFIED_BY_CONTROL | FALSIFIED_BY_CONTROL (unchanged) |
| CLUSTER-02 |  1 | ENVIRONMENTAL | **UNRESOLVED** | REPRODUCED_REPEATEDLY | **OBSERVED_ONCE_UNDER_FULL_SUITE_LOAD** |
| CLUSTER-03 |  1 | PROJECT_DEFECT | **TEST_CONTRACT_AMBIGUITY** | REPRODUCED_REPEATEDLY | REPRODUCED_REPEATEDLY |

Conservation (corrected):
  ENVIRONMENTAL            = 31
  UNRESOLVED               =  1
  TEST_CONTRACT_AMBIGUITY  =  1
  sum                      = 33  (= runner_failed, ok)

Readiness gate:
  natural completion       = true
  inventory complete       = true
  unresolved               = 1
  all failures classified  = true
  no_unknown_red           = FALSE  (one UNRESOLVED present)
  no_production_changes    = TRUE
  DOGFOOD_READY            = FALSE  (gate fails on unresolved > 0;
                                       causally earned, not asserted)
