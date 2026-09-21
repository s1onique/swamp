# Signal microreproducer results (CORRECTION01)

## Setup

- Host: Darwin arm64 arm 23.6.0
- Sandbox: VSCodium Helper (Plugin) --enable-sandbox --service-sandbox-type=none
- Deno runtimes tested:
  - x86_64: /tmp/deno-bin/deno (Mach-O 64-bit executable x86_64)
  - arm64:  /tmp/deno-arm64/deno (Mach-O 64-bit executable arm64)
- Test script: .factory/scripts/signal_microreproducer.ts (v2)
  - 4 cases (M1..M4): SIGTERM/SIGKILL × ChildProcess.kill/Deno.kill
  - Child: SIGTERM-handler trap + 30s setTimeout (no SIGKILL listener)

## Direct host shell test (no Deno)

```
$ /tmp/test_sh_kill.sh
child PID: 91584
/tmp/test_sh_kill.sh: line 7: kill: (91584) - Operation not permitted
kill RC=1
/tmp/test_sh_kill.sh: line 11: kill: (91584) - Operation not permitted
dead
```

`/bin/sh`'s built-in `kill` system call returns EPERM. **The VSCodium Helper
sandbox blocks signal delivery to descendant processes at the OS level.**

## arm64 native Deno

```
M1 (ChildProcess.kill SIGTERM): send-error: EPERM, elapsed=5006ms, exit=null
M2 (Deno.kill          SIGTERM): send-error: EPERM, elapsed=5001ms, exit=null
M3 (ChildProcess.kill SIGKILL): send-error: EPERM, elapsed=5003ms, exit=null
M4 (Deno.kill          SIGKILL): send-error: EPERM, elapsed=5002ms, exit=null
summary: cases=4 completed_in_time=0/4 exit_code_captured=0/4
```

All 4 cases returned `EPERM: Operation not permitted`. The child ran the full
5000ms timeout window on each case.

## x86_64 (Rosetta) Deno

```
M1 (ChildProcess.kill SIGTERM): send-error: EPERM, elapsed=5009ms, exit=null
M2 (Deno.kill          SIGTERM): send-error: EPERM, elapsed=5003ms, exit=null
M3 (ChildProcess.kill SIGKILL): send-error: EPERM, elapsed=5002ms, exit=null
M4 (Deno.kill          SIGKILL): send-error: EPERM, elapsed=5002ms, exit=null
summary: cases=4 completed_in_time=0/4 exit_code_captured=0/4
```

Identical to arm64. Both runtimes exhibit EPERM on signal delivery. Substrate
defect, not Deno-architecture-dependent.

## deno test --allow-all EPERM probe

```
Deno.test("child.kill permission in test context"):
  CHILD_KILL_RESULT: ERR: EPERM: Operation not permitted

Deno.test("Deno.kill in test context"):
  DENO_KILL_RESULT:  ERR: EPERM: Operation not permitted
```

Even within `deno test --allow-all`, both signal APIs return EPERM. The
sandbox blocks signal delivery regardless of Deno permission configuration.

## Sandbox root cause

Parent process tree:
```
74181  73981  /Applications/VSCodium.app/.../VSCodium Helper (Plugin)
        ... --enable-sandbox --service-sandbox-type=none ...
91576  74181  /bin/zsh -c ...
        [this session]
```

`--enable-sandbox` on the VSCodium Helper parent propagates down to all
descendant processes via the macOS sandbox-exec mechanism. Signal delivery
(`kill(2)` syscall) to descendant processes is blocked.

This is the SAME defect class as the 154 mkdir family: an environmental
host-side policy that masquerades as a Swamp/Deno defect.

## Reclassification of the four targets

| target | prior classification | corrected classification |
|---|---|---|
| D1 doctor SIGTERM-respecting | DOCTOR_REPRODUCIBLE_DEFECT | ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL |
| D2 doctor SIGKILL-escalation | DOCTOR_REPRODUCIBLE_DEFECT | ENVIRONMENTAL_SANDBOX_BLOCKS_SIGNAL |
| A1 fmt ANSI                  | ANSI_REPRODUCIBLE_DEFECT   | ENVIRONMENTAL_SANDBOX_INHERITS_FORCED_ANSI |
| A2 lint ANSI                 | ANSI_REPRODUCIBLE_DEFECT   | ENVIRONMENTAL_SANDBOX_INHERITS_FORCED_ANSI |
| 154 mkdir family             | ENVIRONMENTAL              | ENVIRONMENTAL (unchanged) |

