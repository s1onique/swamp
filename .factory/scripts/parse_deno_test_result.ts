// AGPLv3 header — see FILE-LICENSE-TEMPLATE.md
// Deno test result parser for ACT-SWAMP-CHARACTERIZE-REST01.
//
// Reads a captured Deno test runner stdout/stderr (ANSI escapes possible)
// and emits a JSON object describing:
//   natural_completion, runner_summary_line,
//   passed, failed, ignored, total, filtered_out,
//   duration_seconds, failures[].
//
// Deno's per-test failure line shape (post ANSI-strip):
//   ./path/test.ts => group > test name ... FAILED (33ms)
// or with parallel joiner:
//   FAILED | ./path/test.ts > group > test name
//
// Deno's summary line shape:
//   FAILED | 12128 passed (214 steps) | 160 failed | 30 ignored (1 step) (1m40s)
//   ok | 100 passed | 0 failed (5s)
//
// Usage:
//   deno run --allow-read parse_deno_test_result.ts \
//     --stdout capture.stdout [--stderr capture.stderr]
// Output: JSON to stdout.

interface Failure {
  test_name: string;
  test_file: string;
  runner_status: "FAILED" | "ok" | "TIMEOUT" | "UNKNOWN";
  error_lines: string[];
}

interface ParseResult {
  natural_completion: boolean;
  runner_summary_line: string | null;
  passed: number;
  failed: number;
  ignored: number;
  total: number;
  filtered_out: number;
  duration_seconds: number | null;
  failures: Failure[];
}

const ANSI_RE = /\x1b\[[0-9;?]*[ -\/]*[@-~]/g;
const CR_SPINNER_RE = /\r(?!\n)/g;

export function stripAnsi(s: string): string {
  return s.replace(ANSI_RE, "").replace(CR_SPINNER_RE, "\n");
}

export function parseSummary(text: string): {
  line: string;
  passed: number;
  failed: number;
  ignored: number;
  duration: number | null;
} | null {
  // ok | 12128 passed (214 steps) | 160 failed | 30 ignored (1 step) (1m40s)
  // ok | 100 passed | 0 failed (5s)
  // FAILED | N passed (S steps) | M failed | K ignored (T steps) (Xs)
  const re =
    /^[ \t]*(ok|FAILED)[ \t]*\|[ \t]*(\d+)[ \t]+passed[ \t]*(?:\(\d+\s+steps?\))?[ \t]*\|[ \t]*(\d+)[ \t]+failed(?:[ \t]*\|[ \t]*(\d+)[ \t]+ignored[ \t]*(?:\(\d+\s+steps?\))?)?[ \t]*(?:\((\d+)m(\d+)s\)|\((\d+(?:\.\d+)?)s\))?/m;
  const m = text.match(re);
  if (!m) return null;
  let duration: number | null = null;
  if (m[5] !== undefined && m[6] !== undefined) {
    duration = Number(m[5]) * 60 + Number(m[6]);
  } else if (m[7] !== undefined) {
    duration = Number(m[7]);
  }
  return {
    line: m[0].trim(),
    passed: Number(m[2]),
    failed: Number(m[3]),
    ignored: m[4] !== undefined ? Number(m[4]) : 0,
    duration,
  };
}

// Per-failure line: "./path/test.ts => group > test name ... FAILED (33ms)"
// Some pass-through indicators may say "FAILED" in prose. We use the
// distinctive "... FAILED (Nms|Ns|Nµs)" termination to identify real failure
// lines; the lone "FAILED" header at the top of a failures block is also
// matched.
const TEST_RESULT_FAILED_RE =
  /^(?<path>\.[\w\.\/\-]+?\.ts)\s+=>\s+(?<name>.+?)\s+\.\.\.\s+FAILED\s+\((?<dur>[\dµms]+)\)\s*$/;
const PARALLEL_FAILED_HEADER_RE =
  /^[ \t]*FAILED[ \t]*\|[ \t]*(?<name>.+?)\s*$/;
const FILES_HEADER_RE =
  /^[ \t]*[0-9]+\s+\|→\s+.*\.(?<file>\S*_test\.ts)\s+\|.*$/;

export function extractFailures(text: string): Failure[] {
  const out: Failure[] = [];
  const seen = new Set<string>();
  const lines = text.split(/\n/);

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const m1 = raw.match(TEST_RESULT_FAILED_RE);
    if (m1 && m1.groups) {
      const test_file = m1.groups["path"] ?? "";
      const test_name = (m1.groups["name"] ?? "").trim();
      const key = `${test_file}|${test_name}`;
      if (!seen.has(key)) {
        seen.add(key);
        out.push({
          test_name,
          test_file,
          runner_status: "FAILED",
          error_lines: captureErrorLines(lines, i, test_file),
        });
      }
      continue;
    }
    const m2 = raw.match(PARALLEL_FAILED_HEADER_RE);
    if (m2 && m2.groups) {
      const nameish = (m2.groups["name"] ?? "").trim();
      // Skip the runner summary line shape "FAILED | N passed | M failed..."
      if (/^\d+\s+passed/.test(nameish)) continue;
      let test_file = "";
      let test_name = nameish;
      const arrow = nameish.indexOf(" > ");
      if (arrow > 0) {
        test_file = nameish.slice(0, arrow).trim();
        test_name = nameish.slice(arrow + 3).trim();
      }
      const key = `${test_file}|${test_name}`;
      if (!seen.has(key)) {
        seen.add(key);
        out.push({
          test_name,
          test_file,
          runner_status: "FAILED",
          error_lines: captureErrorLines(lines, i, ""),
        });
      }
    }
  }
  return out;
}

function captureErrorLines(
  lines: string[],
  startIdx: number,
  testFile: string,
): string[] {
  const out: string[] = [];
  for (let j = startIdx + 1; j < lines.length; j++) {
    const next = lines[j];
    // Next failure/test/summary — stop
    if (TEST_RESULT_FAILED_RE.test(next)) break;
    if (PARALLEL_FAILED_HEADER_RE.test(next)) break;
    if (/^[ \t]*\bok[ \t]*\|/.test(next)) break;
    if (parseSummary(lines.slice(j).join("\n"))) {
      // We've hit the runner summary; capture up to 5 lines of it
      for (let k = 0; k < 6 && j + k < lines.length; k++) {
        out.push(lines[j + k].replace(/^\s+/, "").trim());
      }
      break;
    }
    if (!testFile) {
      // For parallel-mode blocks, keep lines until next block
      if (/^[ \t]*errors?[ \t]*:/.test(next)) out.push(next.trim());
      if (/^[ \t]*at\s/.test(next)) out.push(next.replace(/^\s+/, "").trim());
      continue;
    }
    // Capture test stack frames
    if (/^[ \t]*at\s/.test(next)) out.push(next.replace(/^\s+/, "").trim());
    else if (/^[ \t]*error[ \t]*:/i.test(next)) out.push(next.replace(/^\s+/, "").trim());
    if (out.length >= 80) break;
  }
  return out;
}

async function readIfExists(path: string | null): Promise<string> {
  if (!path) return "";
  try {
    return await Deno.readTextFile(path);
  } catch {
    return "";
  }
}

function parseArgs(argv: string[]): { stdout: string | null; stderr: string | null } {
  const args: { stdout: string | null; stderr: string | null } = { stdout: null, stderr: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--stdout") args.stdout = argv[++i] ?? null;
    else if (a === "--stderr") args.stderr = argv[++i] ?? null;
    else if (a === "--help" || a === "-h") {
      console.error("Usage: parse_deno_test_result.ts --stdout <file> [--stderr <file>]");
      Deno.exit(2);
    }
  }
  return args;
}

async function main() {
  const args = parseArgs(Deno.args);
  if (!args.stdout) {
    console.error("--stdout is required");
    Deno.exit(2);
  }
  const out = await readIfExists(args.stdout);
  const err = await readIfExists(args.stderr);
  const combined = out + (err ? "\n" + err : "");
  const cleaned = stripAnsi(combined);

  const summary = parseSummary(cleaned);
  const failures = extractFailures(cleaned);

  const result: ParseResult = {
    natural_completion: summary !== null,
    runner_summary_line: summary?.line ?? null,
    passed: summary?.passed ?? 0,
    failed: summary?.failed ?? 0,
    ignored: summary?.ignored ?? 0,
    total: summary ? summary.passed + summary.failed + summary.ignored : 0,
    filtered_out: 0,
    duration_seconds: summary?.duration ?? null,
    failures,
  };

  console.log(JSON.stringify(result, null, 2));
}

if (import.meta.main) {
  await main();
}
