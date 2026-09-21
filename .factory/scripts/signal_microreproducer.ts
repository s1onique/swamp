#!/usr/bin/env -S /tmp/deno-bin/deno run --allow-run --allow-env --allow-read
// signal_microreproducer.ts — Swamp-free subprocess signal experiment.
//
// Spawns a single Deno child that just sleeps for 30 s, then issues four
// signal cases (M1..M4) and records for each:
//   - pid
//   - send_timestamp_ms (relative)
//   - status_resolved_timestamp_ms
//   - elapsed_ms_to_status
//   - terminating_signal
//   - exit_code
//   - pid_alive_after_signal (via Deno.kill(pid, 0))
//
// No Swamp modules imported. Pure Deno primitives.

interface Case {
  readonly id: string;
  readonly signal: "SIGTERM" | "SIGKILL";
  readonly method: "ChildProcess.kill" | "Deno.kill";
}

const CASES: ReadonlyArray<Case> = [
  { id: "M1", signal: "SIGTERM", method: "ChildProcess.kill" },
  { id: "M2", signal: "SIGTERM", method: "Deno.kill" },
  { id: "M3", signal: "SIGKILL", method: "ChildProcess.kill" },
  { id: "M4", signal: "SIGKILL", method: "Deno.kill" },
];

const CHILD_SCRIPT = `
  Deno.addSignalListener("SIGTERM", () => { /* ignore */ });
  await new Promise((r) => setTimeout(r, 30_000));
`;

const T0 = performance.now();

interface CaseResult {
  id: string;
  signal: string;
  method: string;
  pid: number;
  send_ms: number;
  resolved_ms: number;
  elapsed_ms: number;
  exit_code: number | null;
  pid_alive_after_signal: boolean;
  status_completed_in_time: boolean; // < 5000 ms
}

async function runCase(c: Case): Promise<CaseResult> {
  const cmd = new Deno.Command(Deno.execPath(), {
    args: ["eval", CHILD_SCRIPT],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  });
  const child = cmd.spawn();
  const pid = child.pid;
  // Wait briefly so the child is fully started and signal handlers installed.
  await new Promise((r) => setTimeout(r, 200));

  const sendMs = performance.now() - T0;
  let pidAliveAfter = false;
  try {
    Deno.kill(pid, 0);
    pidAliveAfter = true;
  } catch { pidAliveAfter = false; }

  try {
    if (c.method === "ChildProcess.kill") {
      child.kill(c.signal);
    } else {
      Deno.kill(pid, c.signal);
    }
  } catch (e) {
    console.error(`${c.id} send-error: ${(e as Error).message}`);
  }

  // Poll pid liveness for up to 5 s after signal
  let stillAlive = true;
  for (let i = 0; i < 50; i++) {
    try {
      Deno.kill(pid, 0);
      stillAlive = true;
    } catch {
      stillAlive = false;
      break;
    }
    await new Promise((r) => setTimeout(r, 100));
  }

  // Wait up to 5 s for status to resolve
  const statusPromise = child.status;
  const timeout = new Promise<{ code: number; signal: number | null; success: boolean; timedOut: true }>((resolve) => {
    setTimeout(() => resolve({ code: -1, signal: null, success: false, timedOut: true }), 5000);
  });
  const status = await Promise.race([statusPromise, timeout]);

  const resolvedMs = performance.now() - T0;
  const elapsedMs = resolvedMs - sendMs;
  // Force-close stdin so child can proceed
  try { child.stdin.close(); } catch (_e) { /* ignore */ }
  if (status.timedOut) {
    try { Deno.kill(pid, "SIGKILL"); } catch (_e) { /* ignore */ }
  }

  return {
    id: c.id,
    signal: c.signal,
    method: c.method,
    pid,
    send_ms: Math.round(sendMs),
    resolved_ms: Math.round(resolvedMs),
    elapsed_ms: Math.round(elapsedMs),
    exit_code: status.timedOut ? null : status.code,
    pid_alive_after_signal: stillAlive,
    status_completed_in_time: !status.timedOut,
  };
}

const results: CaseResult[] = [];
for (const c of CASES) {
  const r = await runCase(c);
  results.push(r);
  console.log(JSON.stringify(r));
  // Brief pause between cases
  await new Promise((r) => setTimeout(r, 250));
}

// Summary
const total = results.length;
const completedInTime = results.filter((r) => r.status_completed_in_time).length;
const exitCodesNonNull = results.filter((r) => r.exit_code !== null).length;
const aliveAfter = results.filter((r) => r.pid_alive_after_signal).length;
console.error(
  `summary: cases=${total} completed_in_time=${completedInTime}/${total} ` +
    `exit_code_captured=${exitCodesNonNull}/${total} pid_alive_after_signal=${aliveAfter}/${total}`,
);
