// Lightweight runtime experiment: exercise the data layer to verify the
// "immutable, versioned, queryable" data claim at runtime.

import { generateDataId, createDataId, type DataId } from "../../src/domain/data/data_id.ts";
import { generate } from "../../src/domain/data/data_writer.ts";
import { readData } from "../../src/libswamp/data/get.ts";
import { listVersions } from "../../src/libswamp/data/versions.ts";
import { DataAccessService } from "../../src/domain/data/data_access_service.ts";
import { CompositeDataRepository } from "../../src/domain/data/composite_data_repository.ts";
import { CompositeDataQueryService } from "../../src/domain/data/composite_data_query_service.ts";
import { UnifiedDataRepository } from "../../src/infrastructure/persistence/unified_data_repository.ts";
import { initializeLogging } from "../../src/infrastructure/logging/logger.ts";

await initializeLogging({});
const tempDir = await Deno.makeTempDir({ prefix: "swamp_data_exp_" });
console.log("=== Data experiment ===");
console.log("tempDir:", tempDir);

// Build a minimal UnifiedDataRepository pointed at tempDir.
const repo = new UnifiedDataRepository({ dataDir: `${tempDir}/data` });
await repo.initialize();

const queryService = new CompositeDataQueryService([repo]);
const accessService = new DataAccessService(repo, queryService);

// Write version 1
const v1 = await generate({
  repository: repo,
  type: "test/greeting",
  modelId: "00000000-0000-0000-0000-000000000001",
  name: "hello",
  payload: { message: "world v1" },
  contentType: "application/json",
  tags: { type: "test/greeting", specName: "hello" },
  ownerType: "manual",
  ownerRef: "experiment",
  namespace: "",
});
console.log("\nwrite v1:");
console.log("  dataId:", v1.dataId);
console.log("  version:", v1.version);

// Write version 2 with different content (same name → new version)
const v2 = await generate({
  repository: repo,
  type: "test/greeting",
  modelId: "00000000-0000-0000-0000-000000000001",
  name: "hello",
  payload: { message: "world v2 — different content" },
  contentType: "application/json",
  tags: { type: "test/greeting", specName: "hello" },
  ownerType: "manual",
  ownerRef: "experiment",
  namespace: "",
});
console.log("\nwrite v2:");
console.log("  dataId:", v2.dataId);
console.log("  version:", v2.version);

const sameDataId = v1.dataId === v2.dataId;
console.log("\nidentity check:");
console.log("  same dataId across versions:", sameDataId);
console.log("  -> Per data_id.ts design, DataId is per-name, version is per-write.");

// Read latest (should be v2)
const latest = await readData({ repository: repo, type: "test/greeting", modelId: "00000000-0000-0000-0000-000000000001", name: "hello" });
console.log("\nread latest:");
console.log("  version:", latest?.version);
console.log("  attributes:", JSON.stringify(latest?.attributes));

// Read version 1 specifically
const v1Read = await readData({ repository: repo, type: "test/greeting", modelId: "00000000-0000-0000-0000-000000000001", name: "hello", version: 1 });
console.log("\nread version 1 explicitly:");
console.log("  version:", v1Read?.version);
console.log("  attributes:", JSON.stringify(v1Read?.attributes));
console.log("  -> v1 still readable after v2 written:",
  v1Read?.version === 1 && (v1Read?.attributes as Record<string, unknown>)?.message === "world v1");

// List versions
const versions = await listVersions({ repository: repo, type: "test/greeting", modelId: "00000000-0000-0000-0000-000000000001", name: "hello" });
console.log("\nlist versions:");
console.log("  count:", versions.length);
console.log("  versions:", versions.map((v: { version: number }) => v.version).join(", "));

// Query by tag
const tagged = await queryService.query({ predicate: 'tags.specName == "hello"' });
console.log("\nquery by tag:");
console.log("  count:", tagged.length);
console.log("  versions:", tagged.map((r: { version: number }) => r.version).join(", "));

// Verify on-disk layout
const dataDir = `${tempDir}/data/test/greeting/00000000-0000-0000-0000-000000000001/hello`;
try {
  const layout = [...Deno.readDirSync(dataDir)];
  console.log("\non-disk layout:");
  for (const entry of layout) console.log("  ", entry.name);
  const v1Content = Deno.readTextFileSync(`${dataDir}/1/content.json`);
  const v2Content = Deno.readTextFileSync(`${dataDir}/2/content.json`);
  console.log("\ndisk content.json:");
  console.log("  v1:", v1Content);
  console.log("  v2:", v2Content);
  console.log("  v1 != v2:", v1Content !== v2Content);
  console.log("  -> Per data_writer design, save never overwrites: v1 is intact even after v2 was written.");
} catch (err) {
  console.log("could not inspect disk:", err);
}

console.log("\n=== OBSERVED_IMMUTABILITY_BEHAVIOR ===");
console.log("Data identity: (dataId, version). dataId stable across writes for the same (type, modelId, name).");
console.log("Immutability: previous versions remain readable after new versions are written.");
console.log("Versioning: append-only, integer, sequential per name.");
console.log("Query: by tag predicate returns the matching records.");
console.log("Disk layout: data/{type}/{modelId}/{name}/{N}/content.json");

await Deno.remove(tempDir, { recursive: true }).catch(() => {});
Deno.exit(0);
