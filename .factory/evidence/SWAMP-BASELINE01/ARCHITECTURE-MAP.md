# ARCHITECTURE-MAP — Swamp at BASELINE01

This is a bounded map, not exhaustive documentation. Each row answers:

- **component**: name + path
- **responsibility**: what it is
- **important implementation paths**: where it lives
- **inputs**: what feeds it
- **outputs**: what comes out
- **persistent state**: what it writes
- **trust implications**: what an attacker or environment could fake
- **Factory / ClineMM / Mrvn relevance**: where similar mechanisms belong

## 1. The six primitives (per `design/README.md`)

| Primitive | Implementation surface | Notes |
| --- | --- | --- |
| Models | `src/domain/models/`, `src/domain/models/{access,aws,command,worker}/` | typed (zod) representation of external systems; method execution produces Data |
| Definitions | `src/domain/extensions/extension_loader.ts`, `src/infrastructure/persistence/yaml_definition_repository.ts` | YAML instantiations of a model type |
| Workflows | `src/domain/workflows/` (1 file per concept — `workflow.ts`, `job.ts`, `step.ts`, `workflow_run.ts`, `execution_service.ts` (4 678 LoC), `validation_service.ts` (2 500 LoC test)) | DAG of `model_method` / `nested workflow` steps with CEL guards and forEach expansion |
| Data | `src/domain/data/` | versioned, immutable, queryable artifacts of method runs |
| Vaults | `src/domain/vaults/`, `src/infrastructure/persistence/local_encryption_vault_provider.ts` | secrets resolved at run time, never frozen into YAML |
| Extensions | `src/domain/extensions/extension_loader.ts` (subprocess), `extension_api_client.ts` | packaged, published model types, vaults, datastores… |
| Serve | `src/serve/` (~80 files), `src/worker/` (~10 files) | long-running swamp; webhook handlers, dispatch service, data plane, run registry |

## 2. Concrete component map

### CLI entrypoint

- **component**: `main.ts` → `src/cli/mod.ts` `runCli`
- **responsibility**: Cliffy command tree, `--json` mode flag, error rendering, telemetry init, datastore lock teardown
- **inputs**: `Deno.args`, env, `.swamp.yaml`
- **outputs**: stdout (data/JSON) vs stderr (log), exit code
- **persistent state**: `.swamp/` (in repo); `~/.config/swamp/telemetry/` (user-global)
- **trust**: full; CLI is local-process and runs with user identity
- **Factory/ClineMM/Mrvn relevance**: the entrypoint pattern is straightforward; the libswamp context boundary is the lesson — never import from internal `src/libswamp/data/get.ts`, always from `src/libswamp/mod.ts`

### Model abstraction

- **component**: `src/domain/models/model.ts` (1 340 LoC), `model_type.ts`, `model_invocation_service.ts`
- **responsibility**: type + method dispatch; zod input validation; secret redaction; data output writing
- **inputs**: validated zod input record; method context with vault, secrets, data accessor
- **outputs**: method result + written data records
- **persistent state**: `data/{type}/{id}/{name}/{N}/content.json`, `metadata.yaml`
- **trust**: each model is a black box to swamp; an extension author can write any model type. Validation is the trust boundary.
- **Factory/ClineMM/Mrvn relevance**: the typed-model + zod-validated-input pattern is the core abstraction. ClineMM could adopt it directly.

### Definition abstraction

- **component**: `src/domain/extensions/extension_loader.ts`, `extension_loader_subprocess.ts`
- **responsibility**: load extension definitions (manifest + model types + vaults + datastores + reports) from a directory
- **inputs**: extension directory, manifest YAML
- **outputs**: registered extension in repo
- **persistent state**: `.swamp/extensions/`, lockfile, bundled skills
- **trust**: extensions are loaded as **subprocesses** (`extension_loader_subprocess.ts`) for isolation. Subprocess failures are caught. This is a strong trust boundary — extension code cannot corrupt the host.
- **Factory/ClineMM/Mrvn relevance**: subprocess-loading of untrusted code is the right model. Cline bot plugins are NOT isolated this way; that's a structural difference.

### Workflow abstraction

- **component**: `src/domain/workflows/workflow.ts`, `workflow_run.ts`, `execution_service.ts` (4 678 LoC), `topological_sort_service.ts`, `for_each_expansion_service.ts`, `suspended_run_resolver.ts`
- **responsibility**: declare DAG of jobs/steps; resolve CEL guards against `data.*` and `inputs.*`; expand `forEach`; suspend on missing input; resume by replaying completed steps; topological ordering with concurrency cap
- **inputs**: workflow YAML, run inputs, current data catalog
- **outputs**: a workflow run record (`WorkflowRun`), per-step method invocations, data written by method runs
- **persistent state**: `.swamp/workflow-runs/`, `.swamp/workflows-evaluated/`
- **trust**: workflow YAML is git-tracked but evaluated with author-controlled CEL; secrets resolved only at runtime via vault. CEL is sandboxed.
- **Factory/ClineMM/Mrvn relevance**: the DAG + suspend/resume + CEL guards is a strong design point. ClineMM could borrow the DAG model but with simpler node types (no model_method concept).

### Data abstraction

- **component**: `src/domain/data/` (40+ files). `data_id.ts`, `data.ts`, `data_record.ts`, `data_record_mapper.ts`, `data_writer.ts`, `data_lifecycle_service.ts`, `run_lifecycle_service.ts`, `composite_data_repository.ts`, `composite_data_query_service.ts`
- **responsibility**: write immutable, versioned data; resolve latest; expose CEL `data.*` predicates; map `(type, modelId, name, version) ↔ disk path`
- **inputs**: data spec, content payload, owner reference
- **outputs**: data files on disk + catalog SQLite row
- **persistent state**: `data/{type}/{modelId}/{name}/{version}/content.json` plus `metadata.yaml`; catalog in `.swamp/catalog.db` (SQLite)
- **trust**: catalog is local-only, excluded from datastore sync, self-heals from disk (`src/infrastructure/persistence/catalog_store.ts`). Sensitive fields are extracted to vault BEFORE serialization (`data_writer.ts` `processSensitiveResourceData`). Version number is allocated by `mkdir` claim — atomic.
- **Factory/ClineMM/Mrvn relevance**: the data abstraction is the most interesting. DataId is a random UUID, NOT a content hash. Version is an integer. `(dataId, version)` is the stable identity; a bare name resolves to `latest`. This enables cheap reads but breaks content-addressable deduplication — a deliberate trade-off documented in `design/primitives/data.md`.

### Vault abstraction

- **component**: `src/domain/vaults/`, `src/infrastructure/persistence/local_encryption_vault_provider.ts` (conformance tests at `_conformance_test.ts`)
- **responsibility**: secret storage with provider abstraction; local encryption provider (AES-GCM) built-in; 1Password / AWS SM / Azure KV via extensions
- **inputs**: vault config (provider type, master key derivation); secret get/put; audit log
- **outputs**: decrypted secret bytes; secret reference strings
- **persistent state**: `.swamp/vault-bundles/` (encrypted); audit in `.swamp/audit/`
- **trust**: secrets never land in data files. Data writer redacts `sensitive: true` fields and writes `${{ vault.get(...) }}` references. On read, references are resolved and re-registered with the SecretRedactor.
- **Factory/ClineMM/Mrvn relevance**: the secret-redactor pattern is portable. Cline bot doesn't separate secrets from data; that's a structural gap.

### CEL / expression machinery

- **component**: `src/domain/expressions/` (cel_runtime.ts, cel_parser, expression_evaluator, dependency_extractor, vault_reference_extractor, schema_path_validator), `src/infrastructure/cel/cel_evaluator.ts`, `src/infrastructure/cel/workflow_run_filter.ts`, `src/infrastructure/cel/grant_condition_environment.ts`
- **responsibility**: parse CEL, evaluate against a typed environment with `data.*`, `vault.*`, `inputs.*`, `self.*`, `model.method(...)` predicates
- **inputs**: CEL expression string, evaluation context
- **outputs**: typed value (or parse/eval error)
- **persistent state**: evaluated cache persisted with provenance (`src/domain/expressions/expression_evaluators.ts`, fix from `swamp-club#2172`)
- **trust**: cel-js is sandboxed. Path expressions are validated against schema. Vault references are extracted so secret strings never appear in non-vault fields.
- **Factory/ClineMM/Mrvn relevance**: CEL is a strong choice but has a learning curve. ClineMM may want a simpler expression language.

### Workflow scheduler

- **component**: `src/domain/workflows/workflow_scheduler.ts`, `croner` (npm dependency for cron)
- **responsibility**: schedule workflows by cron expression or webhook trigger; resolve trigger inputs from payload
- **inputs**: trigger schedule, trigger source
- **outputs**: workflow run invocation
- **persistent state**: trigger records in `.swamp/workflows-evaluated/`
- **trust**: trigger input sources are validated; webhook signature schemes (Jira, Linear, Stripe, etc.) are validated (`integration/webhook_signature_schemes_test.ts`, all FAILING in this env for the same `repo init` reason — verified structurally)
- **Factory/ClineMM/Mrvn relevance**: webhook + cron triggers are useful; the structure is solid.

### Run persistence

- **component**: `src/domain/data/run_lifecycle_service.ts`, `data_lifecycle_service.ts`, `src/domain/workflows/workflow_run_summary.ts`
- **responsibility**: track run phases (pending → running → suspended → completed/failed/cancelled); aggregate step events into a run summary; allow supersede of suspended runs
- **inputs**: step events, run state changes
- **outputs**: workflow run view
- **persistent state**: workflow run JSON; step event log
- **trust**: idempotent phases. `supersedeSuspendedRuns` is a tool for the operator to safely replace suspended runs.
- **Factory/ClineMM/Mrvn relevance**: phase model is the right shape; the supersede primitive is novel.

### Datastore abstraction

- **component**: `src/domain/datastore/` (datastore_provider, datastore_config, datastore_sync_service, datastore_path_resolver, distributed_lock, datastore_migration_service, control_plane_store), `src/infrastructure/persistence/fs_control_plane_store.ts`, `swamp_sources_repository.ts`
- **responsibility**: control plane (datastore config + sync) plus local filesystem implementation; multi-repo namespaces; distributed locking (`src/domain/datastore/distributed_lock.ts`); per-path signals for sync (`swamp-club#2273`)
- **inputs**: datastore config (local fs, remote provider URL), sync trigger (push/pull), namespace
- **outputs**: synced files
- **persistent state**: `.swamp/` (local); remote provider (e.g. gcs, s3) state
- **trust**: control plane is git-tracked metadata; data plane is remote provider. Lock is OS file lock for local; advisory for remote.
- **Factory/ClineMM/Mrvn relevance**: the multi-repo namespace model (`{ns}/{type}/{modelId}/{name}`) is a strong primitive. ClineMM could adopt it.

### Report / attestation machinery

- **component**: `src/domain/reports/` (report.ts, report_registry.ts, report_execution_service.ts, builtin/), `src/libswamp/reports/`
- **responsibility**: execute a report against a workflow run; produce markdown / JSON / JUnit output
- **inputs**: report type, workflow run reference
- **outputs**: formatted report
- **persistent state**: report output (per-run)
- **trust**: reports are deterministic; the `verification-attestation` report is the one used to gate PRs
- **Factory/ClineMM/Mrvn relevance**: the report registry pattern (built-in + extension-supplied) is a clean way to express summarisation.

### Worker / remote-execution machinery

- **component**: `src/worker/` (connect, dispatch_handler, exec_dispatch, runner_bridge, runner_protocol, data_plane_client, bundle_cache, remote_method_context), `src/serve/dispatch_service.ts`, `worker_gateway.ts`
- **responsibility**: enroll remote workers; dispatch method executions over a WebSocket RPC channel; manage leases, queues, affinity; cancel via run-cancel registry; hot-reload bundles from a registry
- **inputs**: worker enrollment token, method dispatch request
- **outputs**: method execution result; run-cancel events
- **persistent state**: `.swamp/bundles/`, `.swamp/worker-records/`
- **trust**: bearer-token enrollment; HTTP 401 stops after 3 consecutive attempts (`src/worker/connect_test.ts:runWorker: HTTP 401 stops after 3 consecutive attempts` — verified passing). Stale worker records are reaped.
- **Factory/ClineMM/Mrvn relevance**: the connect/dispatch pattern is what Mrvn could leverage for tool distribution.

### Skills

- **component**: `.claude/skills/` (skipped from compile), `src/infrastructure/assets/skill_assets.ts` (copy + supersede), `scripts/review_skills.ts`
- **responsibility**: distribute bundled skills; detect superseded skills and remove; review skill quality
- **inputs**: skill directory
- **outputs**: installed skill
- **persistent state**: `~/.claude/skills/` (per-user) or per-tool config
- **trust**: skills are markdown prompt files, not code. The trust boundary is at the agent running them, not at swamp.
- **Factory/ClineMM/Mrvn relevance**: progressive disclosure of skill descriptions matches the trigger/routing eval pattern (next).

### Skill trigger / routing eval

- **component**: `evals/promptfoo/` (generate_config.ts, generate_routing_config.ts, generate_sufficiency_config.ts), `scripts/eval_skill_triggers_promptfoo.ts`, `deno task eval-skill-triggers`
- **responsibility**: check that skill description triggers fire for the right user queries and don't fire for wrong ones (TPR/FPR); check routing between skills; check sufficiency
- **inputs**: skill definitions, test cases
- **outputs**: pass/fail per case; metric
- **persistent state**: none (eval is ephemeral)
- **trust**: the eval calls the Anthropic API (per `agent-constraints/verification-conventions.md`). Missing `ANTHROPIC_API_KEY` → skip gracefully.
- **Factory/ClineMM/Mrvn relevance**: this is the most important eval signal. Without it, you cannot tell whether skills over- or under-trigger.

### Verification workflows (run by the swamp binary, not Deno directly)

- **component**: `verification/workflow-verify-build.yaml`, `workflow-verify-reviews.yaml`, `workflow-verify-skills.yaml`, `scripts/check_review_verdict.ts`, `verification/review-prompts/{code,adversarial,ux,ci-security}-review.md`
- **responsibility**: orchestrate lint/test/compile steps; run LLM code reviews against the diff; run skill reviews
- **inputs**: commit SHA, branch name
- **outputs**: a workflow run record (history) + a verification attestation
- **persistent state**: `~/.swamp/workflow-runs/` (or wherever the binary puts them — set by `SWAMP_WORKFLOWS_DIR=verification`)
- **trust**: reviews are LLM-judged; verdict parsing is fail-closed (`scripts/check_review_verdict.ts` — see `VERIFICATION-MAP.md`). Guards skip on no-path match; skipped ≠ verified.
- **Factory/ClineMM/Mrvn relevance**: the workflow-of-workflows concept is interesting. ClineMM could repurpose the DAG engine.

### Review verdict machinery

- **component**: `scripts/check_review_verdict.ts` (168 LoC)
- **responsibility**: parse Claude's review output; emit `GATE_VERDICT: pass|fail|missing|provider-error`
- **inputs**: review output file
- **outputs**: exit code 0 (pass) or 1 (anything else)
- **persistent state**: written to log only
- **trust**: line-initial VERDICT marker only; provider errors outrank a marker; <50 bytes = missing; empty output ≠ pass. **Fail-closed on missing marker.** This is the structural defense the commit message claims (`swamp-club#2265`).
- **Factory/ClineMM/Mrvn relevance**: a very portable pattern. Tiny, pure, deterministic.
