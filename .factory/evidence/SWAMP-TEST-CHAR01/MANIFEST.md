# MANIFEST — SWAMP-TEST-CHAR01

Characterization of the BASELINE01 unresolved test failures.

## Subject

```
ACT_HEAD (start of ACT):    20a5fcf694c9bcaf3d82349710f0339e1a63b1b4
ACT_HEAD (commit of result): (committed in this ACT)
BASELINE_SUBJECT:           bcaa9695b7f27f51964a9f41587fdf112b261c89
UPSTREAM_HEAD:              bcaa9695b7f27f51964a9f41587fdf112b261c89
MERGE-BASE:                 bcaa9695b7f27f51964a9f41587fdf112b261c89
```

`git diff --name-only BASELINE_SUBJECT..ACT_HEAD | grep -v '^\.factory/'` is empty.

## Toolchain

```
Deno:  deno 2.9.7 (stable, release, x86_64-apple-darwin)
       v8 15.0.245.2-rusty, typescript 6.0.3
Git:   git version (per `git --version`)
Host:  Darwin
Binary: /tmp/deno-bin/deno  (release binary, no `deno` on default PATH;
        /usr/local/bin and ~/bin unwritable; Nix profile bin on PATH but
        directory does not exist on disk)
```

## Raw evidence layout

```
.factory/tmp/SWAMP-TEST-CHAR01/
├── A/                  real HOME / default cache (cannot start — read-only HOME)
├── B/                  synthetic writable HOME / fresh DENO_DIR / network available
│   ├── B.1.stdout      partial full-suite run (truncated by tool harness SIGTERM)
│   ├── B.1.stderr
│   ├── B.1.run.json
│   └── paths.sh
├── doctor/             isolated repetitions of src/cli/commands/doctor_audit_test.ts (N=5)
├── ansi/               isolated repetitions of src/domain/extensions/extension_quality_checker_test.ts (N=5)
│   ├── control_NO_COLOR.*  env-control: NO_COLOR=1 (still fails)
│   └── control_TERM_dumb.* env-control: TERM=dumb (still fails)
└── telemetry/          control tests under B/C/D
    ├── warm.stdout           Cell C: synthetic HOME + warm DENO_DIR (PASS)
    ├── cached-only.stdout    Cell D: --cached-only (PASS — cache genuinely prewarmed)
    └── cellB-fresh.stdout    Cell B-control: synthetic HOME + fresh DENO_DIR (PASS)
```

## Raw evidence SHA-256 manifest

```
fdade616345a8dbb8d8dd34b627791efda4b7f8a19ae728e549d16c14f44e091  .factory/tmp/SWAMP-TEST-CHAR01/A/environment.txt
cf205dbb8cea84897b488abcc281bf96698d5e94b1096b16657b4caba9082a22  .factory/tmp/SWAMP-TEST-CHAR01/A/exitcode
cb551a80072f13405a0c57306e5c98d84ccc96fba2cb0f1e61f08e85cbe846cb  .factory/tmp/SWAMP-TEST-CHAR01/A/stderr
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  .factory/tmp/SWAMP-TEST-CHAR01/A/stdout
abaa210ea2778b8928f7e7d84ea212545ec3c5d869a5ed0770038d61c488d536  .factory/tmp/SWAMP-TEST-CHAR01/B/B.1.run.json
e4f810410a276d1f496f2fb2060d2f0091b2afc19c545ddf12baa4cd122ef486  .factory/tmp/SWAMP-TEST-CHAR01/B/B.1.stderr
c5f0c730bff346382a3f3a298e78b16db22d1840331dfd474a04a53c785637f5  .factory/tmp/SWAMP-TEST-CHAR01/B/B.1.stdout
ac125643adaae74b93423ebb31f36f6e3ba5e03cad5ed48319509b29bc0afcc4  .factory/tmp/SWAMP-TEST-CHAR01/B/paths.sh
f5dd5f6bec30ef1c3ef21f7ac1a4165c920fb4d8e6d391e170b3ca2e828abc22  .factory/tmp/SWAMP-TEST-CHAR01/ansi/N5.log
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/ansi/control_NO_COLOR.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/ansi/control_NO_COLOR.stderr
1e63bdd8e6bdec750a30c29e15f247f7fa3d4b7f66361ff238c634386ffb720b  .factory/tmp/SWAMP-TEST-CHAR01/ansi/control_NO_COLOR.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/ansi/control_TERM_dumb.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/ansi/control_TERM_dumb.stderr
61dc57461ab1895c27d2c22a8d0b74453e14179d64a02fc04a315629a0141fa5  .factory/tmp/SWAMP-TEST-CHAR01/ansi/control_TERM_dumb.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter1.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter1.stderr
07d633d19e2ffb4d74a71a9d06c01b3acf666ab469f62d6d738a98b183fb9efb  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter1.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter2.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter2.stderr
569380632e306b2bb855dc0ed70d57e291ad8db18e83855e6e879900a080524a  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter2.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter3.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter3.stderr
55dbab485804d3ef34749df5f723195e8b08ae0f745882df3264f9da192fa996  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter3.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter4.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter4.stderr
a31266c4a5791d36ee122de2c0230f582b0678dc8b8fdc3d8fbd3014cb419c27  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter4.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter5.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter5.stderr
29bce1bf53caf22f520dc216fdb836a2b015c6089695673effc3609092b8a790  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iter5.stdout
f5dd5f6bec30ef1c3ef21f7ac1a4165c920fb4d8e6d391e170b3ca2e828abc22  .factory/tmp/SWAMP-TEST-CHAR01/ansi/iterations.txt
4885ceac4707419039a7bedfd19f53692b6060159e07ed61f76e0259d95143a2  .factory/tmp/SWAMP-TEST-CHAR01/doctor/N5.log
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter1.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter1.stderr
a858935f5b352caa910dd03b3e83937359741c2d74ed60dcf0858a36c68b473e  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter1.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter2.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter2.stderr
f65985ec9006317d163b38fe97a2fb645b687d5b0b5311490821d19bd98f4c9b  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter2.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter3.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter3.stderr
2289f207b11e0b6ab46aac02954bda784c5fb15a1018ab6a1ea46bcd271de081  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter3.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter4.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter4.stderr
2b762e4e1df8a0f43cc363fee61706bf99b8f1e931ed24ff78961023e71669cc  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter4.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter5.exitcode
383651964038ece462bfa53bce66fb5295d7d9f224731848004ba15593f0a319  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter5.stderr
08b869577765fedfbf03bd131a173bdff4236717e499422b634ff7796eb7716e  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iter5.stdout
4885ceac4707419039a7bedfd19f53692b6060159e07ed61f76e0259d95143a2  .factory/tmp/SWAMP-TEST-CHAR01/doctor/iterations.txt
ac125643adaae74b93423ebb31f36f6e3ba5e03cad5ed48319509b29bc0afcc4  .factory/tmp/SWAMP-TEST-CHAR01/doctor/paths.sh
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cached-only.exitcode
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cached-only.stderr
80ecc961906a547cb2a3d5fa42b07d7e61fdaf5e6f73ce3092dd9f39c72bebd4  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cached-only.stdout
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cellB-fresh-with-typecheck.stderr
80ecc961906a547cb2a3d5fa42b07d7e61fdaf5e6f73ce3092dd9f39c72bebd4  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cellB-fresh-with-typecheck.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cellB-fresh.exitcode
f84abf483d0ed6c27989ef8c61ff80878296156f5cf86bce0d6eb92d34cf2803  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cellB-fresh.stderr
4b5b812527001c6c71a4245910b40c9dd8b66da798ea6eafbdefaa00f6c1c999  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/cellB-fresh.stdout
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/warm.exitcode
fb304287f5c82817f383a03f271057f5eff897aea9d38417390656ecb496ff1d  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/warm.stderr
80ecc961906a547cb2a3d5fa42b07d7e61fdaf5e6f73ce3092dd9f39c72bebd4  .factory/tmp/SWAMP-TEST-CHAR01/telemetry/warm.stdout
```

(BASELINE01 raw evidence preserved: `ae420afef38fea978bd6a33d0e54971547424aa2c9b8f54310d2b731a7cb9417`)

## Evidence-hygiene

This ACT uses `.factory/scripts/check_evidence_hygiene.sh` for evidence hygiene.
At ACT commit:

```
WHOLE_RANGE_DIFF_CHECK      = EXPECTED_FAIL_RAW_EVIDENCE (test.stdout:17650 trailing blank line)
AUTHORED_ARTIFACTS_DIFF_CHECK = PASS
RAW_EVIDENCE_SHA256_UNCHANGED  = true (ae420afe... == ae420afe...)
```

Three-way invariant holds.

## Normalized evidence

```
.factory/evidence/SWAMP-TEST-CHAR01/normalized/summary.txt
```
