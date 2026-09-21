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

import { Command } from "@cliffy/command";
import {
  auditDoctor,
  consumeStream,
  NoToolConfiguredError,
  type SpawnFn,
} from "../../libswamp/mod.ts";

import {
  SWAMP_SUBDIRS,
  swampPath,
} from "../../infrastructure/persistence/paths.ts";
import { defaultCommandResolver } from "../../infrastructure/process/resolve_command.ts";
import { createAuditDoctorRenderer } from "../../presentation/renderers/audit_doctor.ts";
import { parseAiToolOrThrow } from "../ai_tool_parser.ts";
import {
  createContext,
  type GlobalOptions,
  resolveRepoDir,
} from "../context.ts";
import { resolveDatastoreForRepo } from "../repo_context.ts";
import { UserError } from "../../domain/errors.ts";
import { resolveServeUrl, withRemoteOptions } from "../remote_run.ts";

/**
 * Resolves the target AI tool for `doctor audit`. Priority: explicit
 * `--tool` flag (after validation), then `.swamp.yaml`'s `tool` field.
 * If neither is present, throws `NoToolConfiguredError`.
 *
 * Exported for testing.
 */
export function resolveTargetTool(
  flagTool: string | undefined,
  markerTool: string | undefined,
): string {
  const overrideTool = flagTool ? parseAiToolOrThrow(flagTool) : undefined;
  const resolved = overrideTool ?? markerTool;
  if (!resolved) {
    throw new NoToolConfiguredError();
  }
  return resolved;
}

// deno-lint-ignore no-explicit-any
type AnyOptions = any;

/** Default grace period before SIGKILL escalation. Exported for tests. */
export const DEFAULT_SIGKILL_AFTER_MS = 3_000;

/**
 * Internal seam used by `runChildWithAbort` to deliver a signal to a child
 * process. Production callers never override this — the default delegates to
 * `ChildProcess.kill`. Tests inject a stub to make cancellation outcomes
 * deterministic without depending on whether the host substrate allows
 * signal delivery.
 *
 * NOT a global mutable hook. NOT an environment variable. The seam lives
 * on the function call itself, so production callers cannot be affected.
 */
export type SignalSender = (
  child: Deno.ChildProcess,
  signal: Deno.Signal,
) => void;

/** Production default: `ChildProcess.kill`. */
export const defaultSignalSender: SignalSender = (child, sig) => {
  child.kill(sig);
};

/** Phase of the cancellation pipeline in which a signal was attempted. */
export type CancellationPhase = "graceful" | "escalation";

/**
 * Error raised when a child-process signal could not be delivered.
 *
 * This is distinct from the benign "process already terminated" race: the
 * caller asked for cancellation and the runtime could not honor the
 * request. Callers should not treat this as a successful cancellation;
 * they should surface it (e.g. exit non-zero, log the cause).
 *
 * The `cause` field carries the underlying error from the Deno runtime
 * so diagnostic information is preserved end-to-end.
 */
export class ChildSignalDeliveryError extends UserError {
  readonly signal: Deno.Signal;
  readonly pid?: number;
  readonly phase: CancellationPhase;
  override readonly cause?: unknown;
  constructor(
    message: string,
    options: {
      signal: Deno.Signal;
      pid?: number;
      phase: CancellationPhase;
      cause?: unknown;
    },
  ) {
    super(message, "subprocess_signal_unavailable");
    this.name = "ChildSignalDeliveryError";
    this.signal = options.signal;
    this.pid = options.pid;
    this.phase = options.phase;
    this.cause = options.cause;
  }
}

/**
 * Outcome of attempting to deliver one signal to a child process.
 *
 *   - `delivered`         — the kill() call returned normally; signal may
 *                           or may not have reached the child.
 *   - `already-terminal`  — the runtime indicated the child is no longer
 *                           reachable (e.g. TypeError "Child process has
 *                           already terminated", or Deno.errors.NotFound).
 *                           This is the benign race where the child exited
 *                           in the window between the abort signal arriving
 *                           and our kill() call.
 *   - `capability-denied` — the runtime refused permission
 *                           (`Deno.errors.PermissionDenied`). The signal
 *                           was NOT delivered and the child may still be
 *                           alive. The caller must surface this as a
 *                           bounded failure.
 *   - `failed`            — any other unexpected error. The signal may or
 *                           may not have reached the child. The caller
 *                           must surface this as a bounded failure.
 */
export type SignalAttempt =
  | { kind: "delivered"; signal: Deno.Signal }
  | { kind: "already-terminal"; signal: Deno.Signal }
  | {
    kind: "capability-denied";
    signal: Deno.Signal;
    cause: unknown;
  }
  | { kind: "failed"; signal: Deno.Signal; cause: unknown };

/**
 * Attempt to deliver `signal` to `child` via `sender`, classifying the
 * result. Never throws — every error path becomes a typed outcome.
 *
 * The classification recognises two "already terminal" indicators:
 *   1. `Deno.errors.NotFound` (e.g. `ESRCH: No such process` from `Deno.kill`)
 *   2. A `TypeError` with message `"Child process has already terminated"`
 *      (raised by `ChildProcess.kill` after the child has exited)
 *
 * Anything else is either `Deno.errors.PermissionDenied` (capability
 * denied) or `failed`. The caller MUST treat capability-denied and failed
 * outcomes as bounded errors and must NOT swallow them.
 */
export function attemptSignal(
  child: Deno.ChildProcess,
  signal: Deno.Signal,
  sender: SignalSender,
): SignalAttempt {
  try {
    sender(child, signal);
    return { kind: "delivered", signal };
  } catch (cause: unknown) {
    if (cause instanceof Deno.errors.NotFound) {
      return { kind: "already-terminal", signal };
    }
    // `ChildProcess.kill` after the child has exited raises a plain
    // TypeError; recognise its specific message rather than the whole
    // TypeError class so unrelated TypeErrors are reported as failures.
    if (
      cause instanceof TypeError &&
      (cause as TypeError).message === "Child process has already terminated"
    ) {
      return { kind: "already-terminal", signal };
    }
    if (cause instanceof Deno.errors.PermissionDenied) {
      return { kind: "capability-denied", signal, cause };
    }
    return { kind: "failed", signal, cause };
  }
}

/** Build the `ChildSignalDeliveryError` for a non-delivered attempt. */
function toDeliveryError(
  child: Deno.ChildProcess,
  phase: CancellationPhase,
  attempt:
    | { kind: "capability-denied"; signal: Deno.Signal; cause: unknown }
    | { kind: "failed"; signal: Deno.Signal; cause: unknown },
): ChildSignalDeliveryError {
  const causeMessage = attempt.cause instanceof Error
    ? attempt.cause.message
    : String(attempt.cause);
  const verb = attempt.kind === "capability-denied"
    ? "could not deliver"
    : "failed to deliver";
  const detail = phase === "escalation"
    ? " after the SIGTERM grace period"
    : "";
  const pidPart = typeof child.pid === "number"
    ? ` to child process ${child.pid}`
    : "";
  return new ChildSignalDeliveryError(
    `doctor audit ${verb} ${attempt.signal}${pidPart}${detail}: ${causeMessage}`,
    {
      signal: attempt.signal,
      pid: typeof child.pid === "number" ? child.pid : undefined,
      phase,
      cause: attempt.cause,
    },
  );
}

/**
 * Spawns `cmd`, writes `stdin` to its stdin, and returns the captured
 * exit code and decoded output. While the child runs, an optional
 * `signal` aborts by sending SIGTERM to the child — without this, killing
 * the doctor parent reparents the child to init/launchd instead of
 * tearing it down. If the child ignores SIGTERM, escalates to SIGKILL
 * after `sigkillAfterMs` so a hung subprocess can't keep the doctor
 * alive forever.
 *
 * Cancellation is **capability-aware**: every signal-delivery attempt
 * produces one of four typed outcomes (`delivered`, `already-terminal`,
 * `capability-denied`, `failed`). Non-delivered outcomes surface
 * synchronously as `ChildSignalDeliveryError` rather than silently
 * leaving the caller to await `child.output()` for the child's natural
 * lifetime. This ensures a host whose substrate denies signal delivery
 * (e.g. a sandboxed parent) cannot stall `runChildWithAbort` indefinitely.
 *
 * Exported for testing; production callers go through `makeSwampSpawnFn`.
 */
export async function runChildWithAbort(
  cmd: Deno.Command,
  stdin: string,
  signal: AbortSignal | undefined,
  opts: {
    sigkillAfterMs?: number;
    /**
     * Test seam — replaces the default signal sender. Must NOT be used by
     * production callers; exists only so portable unit tests can drive
     * delivery-failure and capability-denied outcomes deterministically.
     *
     * @internal
     */
    _signalSender?: SignalSender;
  } = {},
): Promise<{ exitCode: number; stdout: string; stderr: string }> {
  if (signal?.aborted) {
    throw new DOMException("doctor audit aborted", "AbortError");
  }
  const sigkillAfterMs = opts.sigkillAfterMs ?? DEFAULT_SIGKILL_AFTER_MS;
  const sendSignal: SignalSender = opts._signalSender ?? defaultSignalSender;
  const child = cmd.spawn();

  // Race the child's natural completion against cancellation. We do not
  // bind `child.output()` directly to the return value, because a denied
  // signal must reject the call *before* `child.output()` resolves — the
  // substrate-defining invariant.
  let resolveSettle: ((v: Deno.CommandOutput) => void) | undefined;
  let rejectSettle: ((e: unknown) => void) | undefined;
  const settled = new Promise<Deno.CommandOutput>((resolve, reject) => {
    resolveSettle = resolve;
    rejectSettle = reject;
  });

  // Begin writing stdin and awaiting the child output in the background.
  // We retain a reference so the finally block can attach a no-op
  // rejection handler if the call was settled by cancellation — without
  // that handler the child eventually exits naturally and surfaces an
  // unhandled rejection (forbidden by project policy).
  const childCompletion: Promise<Deno.CommandOutput> = (async () => {
    const writer = child.stdin.getWriter();
    try {
      await writer.write(new TextEncoder().encode(stdin));
    } finally {
      await writer.close();
    }
    return await child.output();
  })();
  childCompletion.then(
    (v) => resolveSettle?.(v),
    (e) => rejectSettle?.(e),
  );

  let escalationTimer: ReturnType<typeof setTimeout> | undefined;
  let onAbort: (() => void) | undefined;
  if (signal) {
    onAbort = () => {
      const attempt = attemptSignal(child, "SIGTERM", sendSignal);
      if (attempt.kind !== "delivered") {
        if (attempt.kind === "already-terminal") {
          // Child is gone — let `childCompletion` resolve naturally.
          return;
        }
        // capability-denied / failed: surface immediately and do NOT
        // arm the escalation timer (there is nothing to escalate).
        rejectSettle?.(toDeliveryError(child, "graceful", attempt));
        return;
      }
      // SIGTERM delivered; arm escalation if child is still alive at the
      // end of the grace period.
      escalationTimer = setTimeout(() => {
        const esc = attemptSignal(child, "SIGKILL", sendSignal);
        if (esc.kind === "delivered" || esc.kind === "already-terminal") {
          return;
        }
        // capability-denied / failed during escalation: surface.
        if (escalationTimer !== undefined) clearTimeout(escalationTimer);
        rejectSettle?.(toDeliveryError(child, "escalation", esc));
      }, sigkillAfterMs);
    };
    signal.addEventListener("abort", onAbort);
  }

  try {
    const result = await settled;
    const decoder = new TextDecoder();
    return {
      exitCode: result.code,
      stdout: decoder.decode(result.stdout),
      stderr: decoder.decode(result.stderr),
    };
  } finally {
    if (signal && onAbort) signal.removeEventListener("abort", onAbort);
    if (escalationTimer !== undefined) clearTimeout(escalationTimer);
    // If we settled by cancellation (rejected through `rejectSettle`),
    // `childCompletion` is still in flight. Attach a no-op rejection
    // handler so it does not surface as an unhandled rejection when the
    // child eventually exits naturally — its resolution is irrelevant
    // once we have already reported the cancellation failure.
    childCompletion.then(() => {}, () => {});
  }
}

/**
 * Builds a SpawnFn that invokes the currently-running swamp binary against
 * the supplied repo directory. Pins `--repo-dir` on every call so the
 * spawned `audit record` writes into the same repo being audited, not
 * whatever repo the CWD happens to point at.
 *
 * Honours the optional `signal` so a SIGINT against the doctor parent
 * tears down the in-flight child instead of reparenting it to init.
 */
export function makeSwampSpawnFn(repoDir: string): SpawnFn {
  const execPath = Deno.execPath();
  // When running from source (`deno run dev ...`), Deno.execPath() returns
  // the deno binary and Deno.mainModule points at the swamp entrypoint. When
  // running the compiled binary, Deno.execPath() is the compiled swamp and
  // we invoke it directly.
  const runningFromSource = /\/deno(\.exe)?$/.test(execPath);
  return (args, stdin, env = {}, signal) => {
    const argsWithRepo = [...args, "--repo-dir", repoDir];
    const fullArgs = runningFromSource
      ? ["run", "-A", Deno.mainModule, ...argsWithRepo]
      : argsWithRepo;
    const cmd = new Deno.Command(execPath, {
      args: fullArgs,
      stdin: "piped",
      stdout: "piped",
      stderr: "piped",
      env: { ...Deno.env.toObject(), ...env },
    });
    return runChildWithAbort(cmd, stdin, signal);
  };
}

/**
 * `swamp doctor audit` — runs preflight checks against the AI-tool audit
 * integration configured in `.swamp.yaml` (or the tool supplied via
 * `--tool`) and reports per-check pass/fail/skip with actionable hints.
 *
 * Exits non-zero on any check fail so CI can gate on audit integration
 * health.
 */
export const doctorAuditCommand = withRemoteOptions(
  new Command()
    .description(
      "Verify that the AI-tool audit integration is healthy for the configured tool.",
    )
    .example("Check the tool configured in .swamp.yaml", "swamp doctor audit")
    .example("Check a specific tool", "swamp doctor audit --tool kiro")
    .example("Machine-readable output for CI", "swamp doctor audit --json")
    .option(
      "--tool <tool:string>",
      "Override the tool from .swamp.yaml (claude | cursor | kiro | opencode | codex | copilot | none)",
    )
    .option(
      "--repo-dir <dir:string>",
      "Repository directory (env: SWAMP_REPO_DIR)",
    ),
).action(async function (options: AnyOptions) {
  const cliCtx = createContext(options as GlobalOptions, ["doctor", "audit"]);
  cliCtx.logger.debug("Executing doctor audit command");

  const server = resolveServeUrl(options.server as string | undefined);
  if (server) {
    throw new UserError(
      "doctor audit is not supported with --server — it requires local process execution.",
    );
  }

  const repoDir = resolveRepoDir(options.repoDir);
  const { marker } = await resolveDatastoreForRepo(repoDir);
  // Pass the primary enrolled tool (or undefined when no tools are
  // enrolled) so resolveTargetTool throws NoToolConfiguredError only
  // when neither the flag nor the marker provides a tool.
  const resolvedTool = resolveTargetTool(
    options.tool as string | undefined,
    marker?.tools?.[0],
  );

  const auditDir = swampPath(repoDir, SWAMP_SUBDIRS.audit);
  const controller = new AbortController();
  const renderer = createAuditDoctorRenderer(cliCtx.outputMode);

  // Wire SIGINT to the controller so a Ctrl+C tears down any in-flight
  // smoke-test child instead of leaving it reparented to init. After the
  // first signal we remove the listener so a second Ctrl+C falls through
  // to Deno's default exit-130 handler — that gives the user a force-exit
  // escape hatch if a child hangs and ignores SIGTERM. SIGTERM isn't
  // listened for here because Deno doesn't support it on Windows.
  const onSigint = () => {
    try {
      Deno.removeSignalListener("SIGINT", onSigint);
    } catch {
      // Already removed (e.g. doctor finished before signal arrived).
    }
    controller.abort();
  };
  Deno.addSignalListener("SIGINT", onSigint);
  try {
    const commandResolver = defaultCommandResolver();
    await consumeStream(
      auditDoctor({
        repoPath: repoDir,
        auditDir,
        tool: resolvedTool,
        spawnSwamp: makeSwampSpawnFn(repoDir),
        abortSignal: controller.signal,
        resolveBinary: (name) => commandResolver.resolve(name),
      }),
      renderer.handlers(),
    );
  } finally {
    try {
      Deno.removeSignalListener("SIGINT", onSigint);
    } catch {
      // Listener may already be detached on a second signal.
    }
  }

  cliCtx.logger.debug("doctor audit command completed");

  if (renderer.overallStatus === "fail") {
    Deno.exit(1);
  }
});
