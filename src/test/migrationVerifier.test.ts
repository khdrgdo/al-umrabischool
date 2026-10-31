import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { runMigrationAudit } from "../../scripts/verify-migrations";

// يستدعي المنطق الحقيقي لـ scripts/verify-migrations.ts على مجلدات مؤقتة،
// ثم على المستودع الفعلي نفسه.

let tmp: string;

function write(rel: string, content: string) {
  const full = path.join(tmp, rel);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, content, "utf-8");
}

function baseFixture(sql = "CREATE TABLE a(id int);") {
  write("drizzle/migrations/0000_init.sql", sql);
  write("supabase/migrations/20261021000000_init.sql", sql);
  write(
    "drizzle/migrations/meta/_journal.json",
    JSON.stringify({
      version: "7",
      dialect: "postgresql",
      entries: [{ idx: 0, version: "7", when: 1, tag: "0000_init", breakpoints: true }],
    }),
  );
}

beforeEach(() => {
  tmp = fs.mkdtempSync(path.join(os.tmpdir(), "mig-audit-"));
});
afterEach(() => {
  fs.rmSync(tmp, { recursive: true, force: true });
});

describe("Migration verifier (real logic)", () => {
  it("passes a consistent fixture", () => {
    baseFixture();
    const r = runMigrationAudit(tmp);
    expect(r.issues).toEqual([]);
    expect(r.success).toBe(true);
  });

  it("flags a Drizzle file missing from the journal, naming the file", () => {
    baseFixture();
    write("drizzle/migrations/0001_more.sql", "SELECT 1;");
    write("supabase/migrations/20261021000001_more.sql", "SELECT 1;");
    const r = runMigrationAudit(tmp);
    const hit = r.issues.find((i) => i.type === "JOURNAL_UNREGISTERED");
    expect(hit?.message).toContain("0001_more.sql");
    expect(r.success).toBe(false);
  });

  it("flags a Supabase migration with no Drizzle counterpart", () => {
    baseFixture();
    write("supabase/migrations/20261021000005_orphan.sql", "SELECT 1;");
    const r = runMigrationAudit(tmp);
    const hit = r.issues.find((i) => i.type === "COUNTERPART_MISSING");
    expect(hit?.message).toContain("20261021000005_orphan.sql");
  });

  it("flags content drift between the two systems", () => {
    baseFixture();
    write("supabase/migrations/20261021000000_init.sql", "CREATE TABLE b(id int);");
    const r = runMigrationAudit(tmp);
    expect(r.issues.some((i) => i.type === "CONTENT_MISMATCH")).toBe(true);
  });

  it("flags TRUNCATE ... CASCADE inside deployable migrations", () => {
    baseFixture("TRUNCATE TABLE public.students CASCADE;");
    const r = runMigrationAudit(tmp);
    const hits = r.issues.filter((i) => i.type === "DESTRUCTIVE_STATEMENT");
    expect(hits.length).toBe(2); // drizzle + supabase
    expect(hits[0].message).toContain("TRUNCATE");
  });

  it("flags DROP SCHEMA but ignores destructive words that only appear in comments", () => {
    baseFixture("-- TRUNCATE TABLE x;\n/* DROP SCHEMA public; */\nSELECT 1;");
    expect(runMigrationAudit(tmp).success).toBe(true);
    baseFixture("DROP SCHEMA public CASCADE;");
    expect(runMigrationAudit(tmp).issues.some((i) => i.type === "DESTRUCTIVE_STATEMENT")).toBe(true);
  });

  it("flags a seed file that inserts data inside the migrations path", () => {
    baseFixture();
    write("drizzle/migrations/0001_seed_demo.sql", "INSERT INTO t VALUES (1);");
    write("supabase/migrations/20261021000001_seed_demo.sql", "INSERT INTO t VALUES (1);");
    const r = runMigrationAudit(tmp);
    expect(r.issues.some((i) => i.type === "SEED_IN_MIGRATIONS")).toBe(true);
  });

  it("the real repository passes with no destructive statements or journal gaps", () => {
    const r = runMigrationAudit(process.cwd());
    expect(r.issues).toEqual([]);
    expect(r.journalEntriesCount).toBe(r.totalDrizzleFiles);
  });
});
