// signal_microreproducer_faithful.ts
//
// Faithful re-implementation of runChildWithAbort's signal path, with no
// Swamp dependencies. Reproduces the exact code path:
//   - spawn child that blocks for 30s
//   - write+close stdin (matches runChildWithAbort's "writer.write(); writer.close()")
//   - call child.kill(SIGTERM), with optional SIGKILL escalation
//   - await child.output()
//
// Variant A: child with NO SIGTERM handler (matches first doctor test).
// Variant B: child with NO-OP SIGTERM handler (matches second doctor test).

interface Variant {
  readonly name: string;
  readonly childScript: string;
  readonly expectExitWithinMs: number;
}

const VARIANTS: ReadonlyArray<Variant> = [
  {
    name: "A: no SIGTERM handler (should die on SIGTERM)",
    childScript:
      "await new Promise((r) => setTimeout(r, 30_000));",
    expectExitWithinMs: 2_000,
  },
  {
    name: "B: traps SIGTERM (should die on SIGKILL after escalation)",
    childScript:
      "Deno.addSignalListener('SIGTERM', () => {}); " +
      "await new Promise((r) => setTimeout(r, 30_000));",
    expectExitWithinMs: 2_000,
  },
];

const T0 = performance.now();

async function runVariant(v: Variant): Promise<Record<string, unknown>> {
  const cmd = new Deno.Command(Deno.execPath(), {
    args: ["eval", v.childScript],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  });
  const child = cmd.spawn();
  const pid = child.pid;

  // Match runChildWithAbort: write+close stdin, then await child.output().
  const writer = child.stdin.getWriter();
  try {
    await writer.write(new TextEncoder().encode(""));
  } finally {
    await writer.close();
  }

  let escalationTimer: ReturnType<typeof setTimeout> | undefined;
  const sendMs = performance.now() - T0;
  child.kill("SIGTERM");
  escalationTimer = setTimeout(() => {
    try { child.kill("SIGKILL"); } catch (_e) { /* already exited */ }
  }, 200);

  // Track pid liveness in background
  let lastPidAlive = true;
  const livenessProbe = (async () => {
    for (let i = 0; i < 200; i++) {
      try {
        Deno.kill(pid, 0);
        lastPidAlive = true;
      } catch {
        lastPidAlive = false;
        break;
      }
      await new Promise((r) => setTimeout(r, 100));
    }
  })();

  const status = await child.output();
  if (escalationTimer !== undefined) clearTimeout(escalationTimer);
  await livenessProbe.catch(() => {});

  const elapsedMs = performance.now() - T0 - sendMs;
  return {
    variant: v.name,
    pid,
    elapsed_ms: Math.round(elapsedMs),
    pid_alive_after_signal: lastPidAlive,
    exit_code: status.code,
    stdout_empty: status.stdout.length === 0,
    stderr_empty: status.stderr.length === 0,
    meets_expectation: elapsedMs < v.expectExitWithinMs,
  };
}

for (const v of VARIANTS) {
  const r = await runVariant(v);
  console.log(JSON.stringify(r));
}
