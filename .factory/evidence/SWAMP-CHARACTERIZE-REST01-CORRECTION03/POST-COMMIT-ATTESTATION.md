# POST-COMMIT ATTESTATION — SWAMP-CHARACTERIZE-REST01-CORRECTION03

## Subject

  a392c49e1c899fbbbbf39bf84d73a8308c048eb6

## Authority

  This artifact attests Commit A (the content commit).
  It is itself committed as Commit B (the attestation commit).
  It does NOT claim to prove its own cleanliness from inside its
  own contents; it records evidence generated against Commit A.

## ATTESTATION_SUBJECT_COMMIT = Commit A (the content commit)
## ATTESTATION_CONTAINER_COMMIT = Commit B (this attestation commit)

The following fields are populated after the post-commit verifier
runs against Commit A's tree.

## Fields

  CONTENT_COMMIT_SHA              = TBD (filled at Commit B)
  CONTENT_TREE_SHA                = TBD (filled at Commit B)
  ATTESTATION_GENERATED_AT_UTC    = TBD
  SUBJECT                         = a392c49e1c899fbbbbf39bf84d73a8308c048eb6
  POSTCOMMIT_VERIFIER_EXIT        = TBD
  POSTCOMMIT_VERIFIER_TOTAL       = TBD
  POSTCOMMIT_VERIFIER_PASS        = TBD
  POSTCOMMIT_VERIFIER_FAIL        = TBD
  PROJECTION_COUNT                = 8 (derived from manifest.json)
  WORKING_TREE_CLEAN_AT_MEASUREMENT = TBD
  CONTENT_COMMIT_SCOPE_FACTORY_ONLY = TBD

## Raw evidence captured after Commit A exists

  .factory/tmp/SWAMP-CHARACTERIZE-REST01-CORRECTION03/postcommit/
    head.txt      (git rev-parse HEAD captured AFTER Commit A exists)
    tree.txt      (git rev-parse HEAD^{tree} captured AFTER Commit A exists)
    status.txt    (git status --short captured AFTER Commit A exists)
    verifier.stdout       (postcommit verifier output)
    verifier.stderr       (postcommit verifier stderr)
    verifier.exitcode     (postcommit verifier exit code)
    verifier.sha256       (sha256 of the verifier file at post-commit time)
    environment.txt       (deno/os/parent_commit snapshot)
