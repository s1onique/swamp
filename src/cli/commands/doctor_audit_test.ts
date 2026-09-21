// Swamp, an Automation Framework
// Copyright (C) 2026 Elder Swamp Club, Inc.
//
// This file is part of Swamp.
//
// Swamp is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License version 3
// as published by the Free Software Foundation, with the Swamp
// Extension and Definition Exception (found in the "COPYING-EXCEPTION"
// file).
//
// Swamp is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Swamp.  If not, see <https://www.gnu.org/licenses/>.

import { assertEquals, assertRejects, assertThrows } from "@std/assert";
import { initializeLogging } from "../../infrastructure/logging/logger.ts";
import { UserError } from "../../domain/errors.ts";
import { NoToolConfiguredError } from "../../libswamp/mod.ts";

// Import models barrel to trigger self-registration
import "../../domain/models/models.ts";

await initializeLogging({});

Deno.test("doctorAuditCommand module loads", async () => {
  const mod = await import("./doctor_audit.ts");
  assertEquals(typeof mod.doctorAuditCommand, "object");
});

Deno.test("doctorAuditCommand is registered as subcommand of doctorCommand", async () => {
  const { doctorCommand } = await import("./doctor.ts");
  const commands = doctorCommand.getCommands();
  const auditCmd = commands.find((c) => c.getName() === "audit");
  assertEquals(auditCmd !== undefined, true);
});

Deno.test("doctorAuditCommand has the expected option set", async () => {
  const { doctorAuditCommand } = await import("./doctor_audit.ts");
  const options = doctorAuditCommand.getOptions();
  const names = options.map((o) => o.name);
  // Must expose --tool and --repo-dir; inherits --json from the global context
  if (!names.includes("tool")) {
    throw new Error(`expected --tool option, got: ${names.join(", ")}`);
  }
  if (!names.includes("repo-dir")) {
    throw new Error(`expected --repo-dir option, got: ${names.join(", ")}`);
  }
});

Deno.test(
  "resolveTargetTool: returns flag tool when explicit override is provided",
  async () => {
    const { resolveTargetTool } = await import("./doctor_audit.ts");
    assertEquals(resolveTargetTool("kiro", "claude"), "kiro");
  },
);

Deno.test(
  "resolveTargetTool: falls back to marker tool when no flag provided",
  async () => {
    const { resolveTargetTool } = await import("./doctor_audit.ts");
    assertEquals(resolveTargetTool(undefined, "cursor"), "cursor");
  },
);

Deno.test(
  "resolveTargetTool: throws NoToolConfiguredError when neither flag nor marker has a tool",
  async () => {
    const { resolveTargetTool } = await import("./doctor_audit.ts");
    assertThrows(
      () => resolveTargetTool(undefined, undefined),
      NoToolConfiguredError,
    );
  },
);

Deno.test(
  "resolveTargetTool: flag value is validated against the AiTool union (rejects garbage)",
  async () => {
    const { resolveTargetTool } = await import("./doctor_audit.ts");
    // Arbitrary strings must fail validation, not silently pass through
    assertThrows(
      () => resolveTargetTool("not-a-tool", "kiro"),
      UserError,
    );
  },
);

Deno.test(
  "resolveTargetTool: flag wins even when marker is set",
  async () => {
    const { resolveTargetTool } = await import("./doctor_audit.ts");
    assertEquals(resolveTargetTool("opencode", "kiro"), "opencode");
  },
);

Deno.test(
  "resolveTargetTool: accepts the audit-skip tools (codex/none) as valid overrides",
  async () => {
    const { resolveTargetTool } = await import("./doctor_audit.ts");
    // The service short-circuits these to skip; the CLI must still accept them
    // as valid --tool values so the user can explicitly check them.
    assertEquals(resolveTargetTool("codex", undefined), "codex");
    assertEquals(resolveTargetTool("none", undefined), "none");
  },
);

Deno.test(
  "resolveTargetTool: accepts copilot as a valid audit-enabled tool override",
  async () => {
    const { resolveTargetTool } = await import("./doctor_audit.ts");
    assertEquals(resolveTargetTool("copilot", undefined), "copilot");
  },
);

function makeStdinPipedCommand(args: string[]): Deno.Command {
  return new Deno.Command(Deno.execPath(), {
    args,
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  });
}

/**
 * A child fixture that exits cleanly after `exitAfterMs`. Used by the
 * portable cancellation tests so they don't depend on the host substrate
 * permitting signal delivery.
 */
function makeShortLivedCommand(exitAfterMs = 50): Deno.Command {
  return new Deno.Command(Deno.execPath(), {
    args: [
      "eval",
      `await new Promise((r) => setTimeout(r, ${exitAfterMs}));`,
    ],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  });
}

/**
 * Sentinel for `makeRecordingSender`'s `throwOn` array: means "skip this
 * call index (do not throw)". Used to express sequences like
 * `[SKIP, new Deno.errors.PermissionDenied(...)]` (SIGTERM succeeds,
 * SIGKILL denied) without resorting to `null`/`undefined` sentinels
 * that turn into "threw a falsy value" rather than a real signal error.
 */
const SKIP = Symbol("SKIP");

/**
 * Recording signal sender stub: captures each call so tests can assert
 * the exact sequence of (signal, attemptIndex) pairs without depending on
 * the host substrate permitting real signal delivery.
 *
 * The default `throwOn` injects a synthetic `Deno.errors.PermissionDenied`
 * (or any other thrown value) on the matching call index (1-based). Calls
 * with index beyond `throwOn.length` succeed silently — so a stub with
 * `throwOn = [new Deno.errors.PermissionDenied("EPERM")]` denies the
 * SIGTERM attempt and lets SIGKILL through.
 *
 * Use the `SKIP` sentinel in `throwOn` to make a specific call index
 * succeed (e.g. `[SKIP, cause]` = SIGTERM succeeds, SIGKILL throws).
 */
function makeRecordingSender(
  throwOn: ReadonlyArray<unknown>,
): {
  sender: (child: Deno.ChildProcess, signal: Deno.Signal) => void;
  calls: Array<{ signal: Deno.Signal; index: number }>;
} {
  const calls: Array<{ signal: Deno.Signal; index: number }> = [];
  let index = 0;
  const sender = (_child: Deno.ChildProcess, signal: Deno.Signal): void => {
    index += 1;
    calls.push({ signal, index });
    if (index - 1 < throwOn.length) {
      const entry = throwOn[index - 1];
      if (entry !== SKIP) throw entry;
    }
  };
  return { sender, calls };
}

/**
 * Real-signal capability probe.
 *
 * Spawns a short-lived child (natural lifetime: ~250 ms), attempts to
 * deliver SIGTERM via `child.kill`, and classifies the result using the
 * same logic the production code now uses (`attemptSignal`).
 *
 * The probe exists so real-signal integration tests can be **gated** by
 * observed substrate behaviour rather than by hard-coded skip flags. It
 * does NOT inspect the parent process name, environment variables, or
 * any other fingerprint — only whether signal delivery to a descendant
 * is accepted by the substrate.
 *
 * Returns:
 *   `{ canSignal: true,  reason: "delivered" }`     signal accepted
 *   `{ canSignal: false, reason: "PermissionDenied" }`
 *   `{ canSignal: false, reason: "NotFound" }`       race lost
 *   `{ canSignal: false, reason: "Other:<msg>" }`
 *
 * Safe to call multiple times — each call spawns a fresh child with a
 * known short lifetime so a denied signal never produces a >30 s wait.
 */
type CapabilityResult =
  | { canSignal: true; reason: "delivered" }
  | { canSignal: false; reason: "PermissionDenied" }
  | { canSignal: false; reason: "NotFound" }
  | { canSignal: false; reason: `Other:${string}` };

async function probeChildSignalCapability(): Promise<CapabilityResult> {
  const cmd = new Deno.Command(Deno.execPath(), {
    args: ["eval", "await new Promise((r) => setTimeout(r, 250));"],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  });
  const child = cmd.spawn();
  // Briefly yield so the child has time to install handlers and reach a
  // signal-able state. Without this, the kill can race with spawn.
  await new Promise((r) => setTimeout(r, 80));
  let attemptErr: unknown;
  try {
    child.kill("SIGTERM");
  } catch (e) {
    attemptErr = e;
  }
  // Wait briefly for natural termination so a denied signal doesn't leak
  // an orphan process; a denied signal leaves it running for ~250 ms.
  // The probe verdict depends only on whether `child.kill` threw.
  await Promise.race([
    child.output().catch(() => {}),
    new Promise<void>((resolve) => setTimeout(resolve, 1500)),
  ]);
  if (attemptErr === undefined) {
    return { canSignal: true, reason: "delivered" };
  }
  if (attemptErr instanceof Deno.errors.PermissionDenied) {
    return { canSignal: false, reason: "PermissionDenied" };
  }
  if (attemptErr instanceof Deno.errors.NotFound) {
    return { canSignal: false, reason: "NotFound" };
  }
  return {
    canSignal: false,
    reason: `Other:${
      attemptErr instanceof Error ? attemptErr.message : String(attemptErr)
    }`,
  };
}

Deno.test(
  "runChildWithAbort: throws AbortError without spawning when signal is already aborted",
  async () => {
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const controller = new AbortController();
    controller.abort();
    // Use deno itself as a stand-in process — but it should never be spawned
    // because the function must short-circuit on the pre-aborted signal.
    const cmd = makeStdinPipedCommand([
      "eval",
      "console.log('should not run')",
    ]);
    await assertRejects(
      () => runChildWithAbort(cmd, "", controller.signal),
      DOMException,
      "doctor audit aborted",
    );
  },
);

Deno.test(
  "runChildWithAbort: returns normally when child exits cleanly and no abort is requested",
  async () => {
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(50);
    const result = await runChildWithAbort(cmd, "", controller.signal);
    assertEquals(result.exitCode, 0);
  },
);

/**
 * RED — `SIGNAL_CAPABILITY_DENIED_IS_NOT_SILENT`.
 *
 * Demonstrates the defect that the ACT must repair: when the underlying
 * signal-delivery primitive refuses permission, `runChildWithAbort`
 * currently swallows the exception and proceeds to await natural child
 * termination — turning a fast, deterministic "could not signal" failure
 * into a stall bounded only by the child's natural lifetime.
 *
 * The defect is observed by:
 *   1. Driving `runChildWithAbort` with a 5-second-lived child.
 *   2. Aborting after 50 ms (well before the child exits naturally).
 *   3. Injecting a sender that throws `Deno.errors.PermissionDenied` on
 *      the SIGTERM attempt.
 *   4. Asserting that the call resolves *promptly* (<500 ms) and surfaces
 *      the capability denial rather than pretending it succeeded.
 *
 * On the unfixed production code, this test FAILS: the call waits ~5s
 * because the denial is swallowed and `child.output()` only resolves
 * when the child naturally exits.
 */
Deno.test(
  "runChildWithAbort: SIGTERM PermissionDenied is surfaced explicitly, not swallowed",
  // Windows: kill semantics differ; this test is POSIX-only and the
  // overall suite already marks POSIX-only tests with the same condition.
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const { sender } = makeRecordingSender([
      // SIGTERM attempt: PermissionDenied
      new Deno.errors.PermissionDenied("EPERM: Operation not permitted"),
    ]);
    const controller = new AbortController();
    // Long natural lifetime so the unfixed code (swallow + await output)
    // is forced to wait multiple seconds — clearly distinguishing the
    // defect from the bounded fix.
    const cmd = makeShortLivedCommand(5_000);
    // Abort quickly so onAbort actually fires while the child is alive.
    setTimeout(() => controller.abort(), 50);
    const start = performance.now();
    let thrown: unknown;
    try {
      await runChildWithAbort(cmd, "", controller.signal, {
        _signalSender: sender,
      });
    } catch (e) {
      thrown = e;
    }
    const elapsed = performance.now() - start;
    // The fix must ensure this call returns within a small budget regardless
    // of whether the child is still alive.
    if (elapsed > 1_000) {
      throw new Error(
        `expected prompt resolution on SIGTERM PermissionDenied; took ${elapsed}ms ` +
          `(prior defect: swallow + natural child lifetime wait)`,
      );
    }
    // The fix must surface the denial as an explicit, distinguishable error.
    if (!thrown) {
      throw new Error(
        "expected ChildSignalDeliveryError on SIGTERM PermissionDenied; " +
          "got normal completion (denial silently swallowed)",
      );
    }
  },
);

/**
 * T3 — SIGTERM delivered: the sender reports success on SIGTERM. The
 * post-signal child completion path remains valid (no escalation needed
 * because the short-lived child exits naturally after the abort).
 */
Deno.test(
  "runChildWithAbort: portable — SIGTERM delivered, child completes naturally",
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const { sender, calls } = makeRecordingSender([]); // no throws
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(150);
    setTimeout(() => controller.abort(), 30);
    const start = performance.now();
    const result = await runChildWithAbort(cmd, "", controller.signal, {
      _signalSender: sender,
      sigkillAfterMs: 500,
    });
    const elapsed = performance.now() - start;
    if (elapsed > 1_500) {
      throw new Error(
        `expected prompt completion after SIGTERM delivery; took ${elapsed}ms`,
      );
    }
    // Exactly one SIGTERM attempt (no escalation because child exits).
    assertEquals(calls.length, 1);
    assertEquals(calls[0].signal, "SIGTERM");
    assertEquals(result.exitCode, 0);
  },
);

/**
 * T4 — SIGTERM capability denied: the sender raises PermissionDenied.
 * Expected: explicit `ChildSignalDeliveryError`, phase="graceful",
 * signal=SIGTERM, cause preserved. Bounded completion.
 */
Deno.test(
  "runChildWithAbort: portable — SIGTERM PermissionDenied surfaces ChildSignalDeliveryError",
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort, ChildSignalDeliveryError } = await import(
      "./doctor_audit.ts"
    );
    const cause = new Deno.errors.PermissionDenied(
      "EPERM: Operation not permitted",
    );
    const { sender, calls } = makeRecordingSender([cause]);
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(5_000);
    setTimeout(() => controller.abort(), 30);
    const start = performance.now();
    let thrown: unknown;
    try {
      await runChildWithAbort(cmd, "", controller.signal, {
        _signalSender: sender,
        sigkillAfterMs: 200,
      });
    } catch (e) {
      thrown = e;
    }
    const elapsed = performance.now() - start;
    if (elapsed > 500) {
      throw new Error(
        `expected bounded completion on SIGTERM PermissionDenied; took ${elapsed}ms`,
      );
    }
    assertEquals(calls.length, 1);
    assertEquals(calls[0].signal, "SIGTERM");
    if (!(thrown instanceof ChildSignalDeliveryError)) {
      throw new Error(
        `expected ChildSignalDeliveryError; got ${
          thrown instanceof Error ? thrown.constructor.name : typeof thrown
        }`,
      );
    }
    assertEquals(thrown.signal, "SIGTERM");
    assertEquals(thrown.phase, "graceful");
    if (thrown.cause !== cause) {
      throw new Error("expected cause preserved");
    }
  },
);

/**
 * T5 — generic SIGTERM failure: the sender raises an arbitrary error
 * that is neither NotFound, nor the "already terminated" TypeError, nor
 * PermissionDenied. Expected: explicit `ChildSignalDeliveryError`,
 * phase="graceful", signal=SIGTERM, cause preserved.
 */
Deno.test(
  "runChildWithAbort: portable — generic SIGTERM failure surfaces ChildSignalDeliveryError",
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort, ChildSignalDeliveryError } = await import(
      "./doctor_audit.ts"
    );
    const cause = new Error("synthetic boom");
    const { sender, calls } = makeRecordingSender([cause]);
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(5_000);
    setTimeout(() => controller.abort(), 30);
    const start = performance.now();
    let thrown: unknown;
    try {
      await runChildWithAbort(cmd, "", controller.signal, {
        _signalSender: sender,
        sigkillAfterMs: 200,
      });
    } catch (e) {
      thrown = e;
    }
    const elapsed = performance.now() - start;
    if (elapsed > 500) {
      throw new Error(
        `expected bounded completion on generic SIGTERM failure; took ${elapsed}ms`,
      );
    }
    assertEquals(calls.length, 1);
    assertEquals(calls[0].signal, "SIGTERM");
    if (!(thrown instanceof ChildSignalDeliveryError)) {
      throw new Error(
        `expected ChildSignalDeliveryError; got ${
          thrown instanceof Error ? thrown.constructor.name : typeof thrown
        }`,
      );
    }
    assertEquals(thrown.signal, "SIGTERM");
    assertEquals(thrown.phase, "graceful");
    if (thrown.cause !== cause) {
      throw new Error("expected cause preserved");
    }
  },
);

/**
 * T6 — SIGKILL escalation success: SIGTERM delivered, escalation timer
 * fires, SIGKILL delivered. Expected signal sequence: SIGTERM then
 * SIGKILL, exactly once each.
 *
 * To keep the test bounded without coupling to the natural child
 * lifetime, the call is raced against a 1500 ms budget: we assert on
 * the recorded signal sequence within the budget; the call itself may
 * continue past the budget while the long-lived child completes.
 */
Deno.test(
  "runChildWithAbort: portable — SIGTERM delivered then SIGKILL escalation delivered",
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const { sender, calls } = makeRecordingSender([]);
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(30_000);
    setTimeout(() => controller.abort(), 30);
    let thrown: unknown;
    runChildWithAbort(cmd, "", controller.signal, {
      _signalSender: sender,
      sigkillAfterMs: 80,
    }).catch((e: unknown) => {
      thrown = e;
    });
    // Poll for the SIGKILL signal to be recorded within the budget.
    const deadline = performance.now() + 1500;
    while (calls.length < 2 && performance.now() < deadline) {
      await new Promise((r) => setTimeout(r, 20));
    }
    if (calls.length < 2) {
      throw new Error(
        `expected SIGKILL to be delivered within 1500 ms; only saw ${calls.length} call(s)`,
      );
    }
    assertEquals(calls[0].signal, "SIGTERM");
    assertEquals(calls[1].signal, "SIGKILL");
    if (thrown) {
      throw new Error(
        `expected no error on successful escalation; got ${
          thrown instanceof Error ? thrown.message : String(thrown)
        }`,
      );
    }
  },
);

/**
 * T7 — SIGKILL capability denied: SIGTERM delivered, grace expires,
 * SIGKILL raises PermissionDenied. Expected: explicit
 * `ChildSignalDeliveryError`, phase="escalation", signal=SIGKILL,
 * cause preserved, bounded completion.
 */
Deno.test(
  "runChildWithAbort: portable — SIGTERM delivered then SIGKILL PermissionDenied surfaces ChildSignalDeliveryError",
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort, ChildSignalDeliveryError } = await import(
      "./doctor_audit.ts"
    );
    const cause = new Deno.errors.PermissionDenied(
      "EPERM: Operation not permitted",
    );
    const { sender, calls } = makeRecordingSender([
      SKIP, // SIGTERM: succeed (no-op)
      cause, // SIGKILL: denied
    ]);
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(30_000);
    setTimeout(() => controller.abort(), 30);
    const start = performance.now();
    let thrown: unknown;
    try {
      await runChildWithAbort(cmd, "", controller.signal, {
        _signalSender: sender,
        sigkillAfterMs: 80,
      });
    } catch (e) {
      thrown = e;
    }
    const elapsed = performance.now() - start;
    if (elapsed > 1_500) {
      throw new Error(
        `expected bounded completion on SIGKILL PermissionDenied; took ${elapsed}ms`,
      );
    }
    assertEquals(calls.length, 2);
    assertEquals(calls[0].signal, "SIGTERM");
    assertEquals(calls[1].signal, "SIGKILL");
    if (!(thrown instanceof ChildSignalDeliveryError)) {
      throw new Error(
        `expected ChildSignalDeliveryError on SIGKILL denial; got ${
          thrown instanceof Error ? thrown.constructor.name : typeof thrown
        }`,
      );
    }
    assertEquals(thrown.signal, "SIGKILL");
    assertEquals(thrown.phase, "escalation");
    if (thrown.cause !== cause) {
      throw new Error("expected cause preserved on escalation");
    }
  },
);

/**
 * T8 — terminal race: the sender simulates "child already gone" on
 * the SIGTERM attempt (TypeError("Child process has already
 * terminated")). Expected: NO false capability-denied diagnosis, NO
 * double settlement, the call resolves normally via the existing
 * `child.output()` path.
 */
Deno.test(
  "runChildWithAbort: portable — terminal race returns benign already-terminal outcome, not delivery error",
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort, ChildSignalDeliveryError } = await import(
      "./doctor_audit.ts"
    );
    const alreadyGone = new TypeError("Child process has already terminated");
    const { sender, calls } = makeRecordingSender([alreadyGone]);
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(30);
    setTimeout(() => controller.abort(), 100);
    const start = performance.now();
    let thrown: unknown;
    let result: Awaited<ReturnType<typeof runChildWithAbort>> | undefined;
    try {
      result = await runChildWithAbort(cmd, "", controller.signal, {
        _signalSender: sender,
        sigkillAfterMs: 200,
      });
    } catch (e) {
      thrown = e;
    }
    const elapsed = performance.now() - start;
    if (elapsed > 1_000) {
      throw new Error(
        `expected prompt benign completion; took ${elapsed}ms`,
      );
    }
    assertEquals(calls.length, 1);
    assertEquals(calls[0].signal, "SIGTERM");
    if (thrown instanceof ChildSignalDeliveryError) {
      throw new Error(
        "expected NO delivery error on benign terminal race; got " +
          thrown.message,
      );
    }
    if (thrown) {
      throw new Error(
        "expected benign completion on terminal race; got " +
          (thrown instanceof Error ? thrown.message : String(thrown)),
      );
    }
    if (!result) throw new Error("expected benign completion");
    assertEquals(result.exitCode, 0);
  },
);

Deno.test(
  "runChildWithAbort: throws AbortError without spawning when signal is already aborted",
  async () => {
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const controller = new AbortController();
    controller.abort();
    // Use deno itself as a stand-in process — but it should never be spawned
    // because the function must short-circuit on the pre-aborted signal.
    const cmd = makeStdinPipedCommand([
      "eval",
      "console.log('should not run')",
    ]);
    await assertRejects(
      () => runChildWithAbort(cmd, "", controller.signal),
      DOMException,
      "doctor audit aborted",
    );
  },
);

Deno.test(
  "runChildWithAbort: aborting a SIGTERM-respecting child terminates it promptly [real-signal]",
  // SIGTERM is not a portable kill signal on Windows; the underlying Deno
  // ChildProcess.kill semantics differ. The bug being fixed is POSIX-only.
  { ignore: Deno.build.os === "windows" },
  async () => {
    const cap = await probeChildSignalCapability();
    if (!cap.canSignal) {
      console.log(
        `[capability-gated skip] CAN_SIGNAL_CHILD=false reason=${cap.reason} ` +
          "(host substrate denies process signal delivery)",
      );
      return;
    }
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const controller = new AbortController();
    const cmd = makeStdinPipedCommand([
      "eval",
      "await new Promise((r) => setTimeout(r, 30_000));",
    ]);
    const start = performance.now();
    setTimeout(() => controller.abort(), 100);
    const result = await runChildWithAbort(cmd, "", controller.signal);
    const elapsed = performance.now() - start;
    if (elapsed > 2_000) {
      throw new Error(
        `expected SIGTERM-responding child to exit promptly; took ${elapsed}ms`,
      );
    }
    assertEquals(result.exitCode === 0, false);
  },
);

Deno.test(
  "runChildWithAbort: escalates to SIGKILL when child traps SIGTERM [real-signal]",
  async () => {
    const cap = await probeChildSignalCapability();
    if (!cap.canSignal) {
      console.log(
        `[capability-gated skip] CAN_SIGNAL_CHILD=false reason=${cap.reason} ` +
          "(host substrate denies process signal delivery)",
      );
      return;
    }
    const { runChildWithAbort } = await import("./doctor_audit.ts");
    const controller = new AbortController();
    const cmd = makeStdinPipedCommand([
      "eval",
      "Deno.addSignalListener('SIGTERM', () => {}); " +
      "await new Promise((r) => setTimeout(r, 30_000));",
    ]);
    const start = performance.now();
    setTimeout(() => controller.abort(), 100);
    const result = await runChildWithAbort(cmd, "", controller.signal, {
      sigkillAfterMs: 200,
    });
    const elapsed = performance.now() - start;
    if (elapsed > 2_000) {
      throw new Error(
        `expected SIGKILL escalation to terminate child; took ${elapsed}ms`,
      );
    }
    assertEquals(result.exitCode === 0, false);
  },
);

Deno.test(
  "capability-probe: reports CAN_SIGNAL_CHILD verdict for current substrate",
  async () => {
    const cap = await probeChildSignalCapability();
    console.log(
      `CAN_SIGNAL_CHILD=${cap.canSignal} reason=${cap.reason}`,
    );
    if (typeof cap.canSignal !== "boolean") {
      throw new Error("probe result must include canSignal boolean");
    }
  },
);

Deno.test(
  "runChildWithAbort: ChildSignalDeliveryError is not converted to success [caller]",
  { ignore: Deno.build.os === "windows" },
  async () => {
    const { runChildWithAbort, ChildSignalDeliveryError } = await import(
      "./doctor_audit.ts"
    );
    const { sender } = makeRecordingSender([
      new Deno.errors.PermissionDenied("EPERM: Operation not permitted"),
    ]);
    const controller = new AbortController();
    const cmd = makeShortLivedCommand(5_000);
    setTimeout(() => controller.abort(), 30);
    let result: Awaited<ReturnType<typeof runChildWithAbort>> | undefined;
    let thrown: unknown;
    try {
      result = await runChildWithAbort(cmd, "", controller.signal, {
        _signalSender: sender,
      });
    } catch (e) {
      thrown = e;
    }
    if (result) {
      throw new Error(
        "expected rejection on denied signal; got success result with " +
          `exitCode=${result.exitCode}`,
      );
    }
    if (!(thrown instanceof ChildSignalDeliveryError)) {
      throw new Error(
        "expected ChildSignalDeliveryError; got " +
          (thrown instanceof Error ? thrown.constructor.name : typeof thrown),
      );
    }
    assertEquals(result, undefined);
  },
);
