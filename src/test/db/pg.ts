import pg from "pg";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

// اختبارات على PostgreSQL حقيقي: تُطبَّق ترحيلات supabase/migrations الفعلية كما هي
// فوق هيكل Supabase الأدنى (الأدوار + auth.users + auth.uid()). لا يُستبدل أي كائن من المشروع.
// يتطلب متغير TEST_DATABASE_URL يشير إلى خادم PostgreSQL قابل للإتلاف (يُنشأ لكل ملف اختبار
// قاعدة مؤقتة ثم تُحذف). في CI يجب أن يكون المتغير مضبوطاً وإلا يفشل الاختبار (لا تخطٍّ صامت).

export const TEST_DB_URL = process.env["TEST_DATABASE_URL"];
if (!TEST_DB_URL && process.env["CI"]) {
  throw new Error("CI requires TEST_DATABASE_URL: DB integration tests must not be skipped silently.");
}
export const dbEnabled = Boolean(TEST_DB_URL);

const BOOTSTRAP = `
  DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN BYPASSRLS; END IF;
  END $$;
  CREATE SCHEMA IF NOT EXISTS auth; CREATE SCHEMA IF NOT EXISTS extensions;
  CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;
  GRANT USAGE ON SCHEMA public, auth, extensions TO anon, authenticated, service_role;
  CREATE TABLE auth.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(), email text UNIQUE,
    raw_user_meta_data jsonb, created_at timestamptz DEFAULT now()
  );
  CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
    $f$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $f$;
  CREATE FUNCTION auth.role() RETURNS text LANGUAGE sql STABLE AS
    $f$ SELECT coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), 'anon') $f$;
  -- افتراضات Supabase: الكائنات الجديدة في public مفتوحة لأدوار الـ API (RLS/REVOKE هما الحد الفاصل).
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;
`;

export type Actor = { kind: "anon" } | { kind: "service" } | { kind: "user"; id: string };

export interface TestDb {
  client: pg.Client;
  as<T>(actor: Actor, fn: (c: pg.Client) => Promise<T>): Promise<T>;
  /** يعيد نتيجة خطأ بدل الرمي — للتأكد من أن الاستعلام مرفوض */
  tryAs(actor: Actor, sql: string, params?: unknown[]): Promise<{ ok: boolean; rows: any[]; error?: string }>;
  newUser(email: string): Promise<string>;
  /** يطبّق ملف ترحيل واحد (بصلاحية superuser) */
  applyMigration(file: string): Promise<void>;
  /** يشغّل SQL بصلاحية superuser (تجهيز بيانات) */
  sql(text: string, params?: unknown[]): Promise<any[]>;
  /** يشغّل seed الاختبار المحمي بعد ضبط حارس البيئة */
  seed(): Promise<void>;
  close(): Promise<void>;
}

export async function createDb(opts: { upTo?: string; dir?: string } = {}): Promise<TestDb> {
  if (!TEST_DB_URL) throw new Error("TEST_DATABASE_URL is not set");
  const name = `t_${crypto.randomBytes(6).toString("hex")}`;
  const admin = new pg.Client(TEST_DB_URL);
  await admin.connect();
  await admin.query(`CREATE DATABASE ${name}`);
  const u = new URL(TEST_DB_URL);
  u.pathname = `/${name}`;
  const client = new pg.Client(u.toString());
  await client.connect();
  await client.query(BOOTSTRAP);
  const dir = opts.dir ?? path.join(process.cwd(), "supabase", "migrations");
  for (const f of fs.readdirSync(dir).filter((x) => x.endsWith(".sql")).sort()) {
    if (opts.upTo && f > opts.upTo) break;
    try {
      await client.query(fs.readFileSync(path.join(dir, f), "utf-8"));
    } catch (e) {
      throw new Error(`migration ${f} failed: ${(e as Error).message}`);
    }
  }
  const setActor = async (a: Actor) => {
    await client.query("RESET ROLE");
    if (a.kind === "service") {
      await client.query("SET ROLE service_role");
      await client.query("SELECT set_config('request.jwt.claim.sub','',false)");
    } else if (a.kind === "anon") {
      await client.query("SET ROLE anon");
      await client.query("SELECT set_config('request.jwt.claim.sub','',false)");
    } else {
      await client.query("SET ROLE authenticated");
      await client.query("SELECT set_config('request.jwt.claim.sub',$1,false)", [a.id]);
    }
  };
  return {
    client,
    async as(a, fn) {
      await setActor(a);
      try { return await fn(client); } finally { await client.query("RESET ROLE"); }
    },
    async tryAs(a, sql, params = []) {
      await setActor(a);
      await client.query("SAVEPOINT s").catch(() => undefined);
      try {
        const r = await client.query(sql, params as any[]);
        return { ok: true, rows: r.rows };
      } catch (e) {
        await client.query("ROLLBACK TO SAVEPOINT s").catch(() => undefined);
        return { ok: false, rows: [], error: (e as Error).message };
      } finally {
        await client.query("RESET ROLE");
      }
    },
    async newUser(email) {
      const r = await client.query("INSERT INTO auth.users (email, raw_user_meta_data) VALUES ($1,'{}') RETURNING id", [email]);
      return r.rows[0].id as string;
    },
    async applyMigration(file) {
      await client.query(fs.readFileSync(path.join(dir, file), "utf-8"));
    },
    async sql(text, params = []) {
      return (await client.query(text, params as any[])).rows;
    },
    async seed() {
      await client.query("SELECT set_config('app.seed_environment','test',false)");
      await client.query("SELECT set_config('app.seed_confirm','I-CONFIRM-THIS-IS-A-DISPOSABLE-TEST-DATABASE',false)");
      await client.query(fs.readFileSync(path.join(process.cwd(), "supabase", "test-seed", "seed_test_data.sql"), "utf-8"));
    },
    async close() {
      await client.end();
      await admin.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
      await admin.end();
    },
  };
}
