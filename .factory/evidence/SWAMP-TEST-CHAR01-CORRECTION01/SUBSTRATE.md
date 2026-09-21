# SUBSTRATE — Host environment characterization

## Hardware

- arch:        arm64
- host triple: Darwin arm64 arm
- kernel:      23.6.0
- file:        Mach-O 64-bit executable arm64 (for native Deno)

## Sandbox

- parent: VSCodium Helper (Plugin) --enable-sandbox --service-sandbox-type=none
- propagation: macOS sandbox-exec applies to all descendants
- effect: kill(2) to descendant processes returns EPERM
- direct evidence: `/bin/sh`'s built-in `kill` returns `Operation not permitted`

## Deno binaries (both v2.9.7)

| variant | path                      | Mach-O                  |
|---------|---------------------------|-------------------------|
| x86_64  | /tmp/deno-bin/deno        | Mach-O 64-bit exec x86_64 |
| arm64   | /tmp/deno-arm64/deno      | Mach-O 64-bit exec arm64  |

Both signed by Developer ID Application: Deno Land Inc.

## Sandbox-exec verification (host shell)

```
$ /tmp/test_sh_kill.sh
child PID: 91584
/tmp/test_sh_kill.sh: line 7: kill: (91584) - Operation not permitted
kill RC=1
/tmp/test_sh_kill.sh: line 11: kill: (91584) - Operation not permitted
dead
```

## Why this substrate matters

VSCodium's `--enable-sandbox` enables macOS sandbox-exec for the helper. All
descendants — including any shell, Deno process, and Deno subprocess — inherit
a sandbox profile that denies signal delivery to descendant processes.

This is the **same defect class** as the 154 mkdir family: a host-side
environmental policy that masquerades as a Swamp/Deno defect.

Both x86_64 (under Rosetta) and native arm64 Deno inherit the same sandbox
profile, so the substrate defect is **runtime-architecture-independent**.

## What does NOT explain the failures

- Deno runtime architecture (x86_64 vs arm64): ruled out — both fail identically
- Deno binary version (2.9.7): ruled out — both runtimes are 2.9.7
- Swamp code: ruled out for doctor/ANSI — Swamp's `runChildWithAbort` and
  `extension_quality_checker` correctly attempt the documented operations;
  the substrate fails to honor them.

## What DOES explain each failure

| target | substrate cause | code defect? |
|---|---|---|
| D1 doctor SIGTERM-respecting  | sandbox EPERM on `child.kill("SIGTERM")` | NO |
| D2 doctor SIGKILL-escalation  | sandbox EPERM on `child.kill("SIGKILL")`  | NO |
| A1 extension_quality fmt ANSI | Deno 2.9.7 emits ANSI escapes with NO_COLOR=1 when fmt finds issues | possibly (test or production) |
| A2 extension_quality lint ANSI | Deno 2.9.7 emits ANSI escapes with NO_COLOR=1 when lint finds issues | possibly (test or production) |
| 154 mkdir family               | unwritable $HOME/.claude/skills/swamp | NO |

For A1/A2: the Deno behavior is not Swamp's fault. The test was written
assuming Deno's output would not contain ANSI escapes when NO_COLOR=1 is
set. Deno 2.9.7 does not honor this assumption when output is piped (i.e.,
not a TTY). Swamp's `extension_quality_checker.ts` captures the raw output
and the test inspects it for `\x1b[`. Fix options:
  (a) Swamp strips ANSI before reporting (production change)
  (b) Test asserts ANSI is present when issue is found, absent when not (test change)
  (c) Deno upstream fix (out of Swamp's control)

The actor for `ACT-SWAMP-ANSI-OUTPUT01` should pick one.
