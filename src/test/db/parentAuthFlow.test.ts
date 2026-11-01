// @vitest-environment node
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createDb, dbEnabled, type TestDb } from "./pg";
import { handleParentActivation, parentLoginEmail, type ParentAuthDeps } from "@/lib/parentAuth.server";

// تكامل حقيقي: خدمة التفعيل ← دوال PostgreSQL الفعلية (بصلاحية service_role) ← لوحة ولي الأمر بجلسته.
describe.skipIf(!dbEnabled)("تدفق التفعيل الكامل مع قاعدة البيانات الحقيقية", () => {
  let db: TestDb;
  let principal: string;
  let gid: string;
  const authUsers = new Map<string, { id: string; guardian: boolean; password: string }>();

  const realDeps = (): ParentAuthDeps => ({
    async checkActivation(accountCode, code) {
      const r = await db.tryAs({ kind: "service" }, "SELECT public.parent_check_activation($1,$2) AS r", [accountCode, code]);
      return r.ok ? r.rows[0].r : null;
    },
    async completeActivation(g, u) {
      const r = await db.tryAs({ kind: "service" }, "SELECT public.parent_complete_activation($1,$2) AS r", [g, u]);
      return r.ok && r.rows[0].r === true;
    },
    async createAuthUser(email, password) {
      if (authUsers.has(email)) return { error: "exists" };
      const id = await db.newUser(email);
      authUsers.set(email, { id, guardian: true, password });
      return { id };
    },
    async findAuthUserByEmail(email) {
      const u = authUsers.get(email);
      return u ? { id: u.id, isGuardian: u.guardian } : null;
    },
    async deleteAuthUser(id) {
      for (const [k, v] of authUsers) if (v.id === id) authUsers.delete(k);
      await db.sql("DELETE FROM auth.users WHERE id=$1", [id]);
    },
    async updateAuthPassword(id, password) {
      for (const v of authUsers.values()) if (v.id === id) v.password = password;
      return true;
    },
  });

  beforeAll(async () => {
    db = await createDb();
    await db.seed();
    principal = await db.newUser("principal@school.test");
    await db.sql("DELETE FROM public.user_roles");
    await db.sql("INSERT INTO public.user_roles (user_id, role) VALUES ($1,'principal')", [principal]);
    gid = (await db.sql("SELECT id FROM public.guardians WHERE account_code='PAR-20202'"))[0].id;
    await db.sql("UPDATE public.guardians SET status='pending_activation' WHERE id=$1", [gid]);
  }, 120000);
  afterAll(async () => { await db?.close(); });

  const issue = async () =>
    (await db.tryAs({ kind: "user", id: principal }, "SELECT public.admin_reset_guardian_password($1) AS r", [gid])).rows[0].r as any;
  const dash = async (uid: string) =>
    (await db.as({ kind: "user", id: uid }, async (c) => (await c.query("SELECT public.parent_get_dashboard_data() AS d")).rows[0].d)) as any;

  it("إصدار ← تفعيل ← لوحة ولي الأمر تعرض أبناءه فقط", async () => {
    const t = await issue();
    expect(t.purpose).toBe("activate");
    const res = await handleParentActivation({ account_code: t.account_code, activation_code: t.activation_code, password: "Parent-Pass-1" }, realDeps());
    expect(res.status).toBe(200);
    const user = authUsers.get(parentLoginEmail(t.account_code))!;
    const d = await dash(user.id);
    expect(d.error).toBeUndefined();
    expect(d.children.length).toBe(1);
  });
  it("الرمز نفسه لا يعمل مرة ثانية", async () => {
    const t = await issue();
    const first = await handleParentActivation({ account_code: t.account_code, activation_code: t.activation_code, password: "Another-Pass-2" }, realDeps());
    expect(first.status).toBe(200); // purpose=reset الآن
    const second = await handleParentActivation({ account_code: t.account_code, activation_code: t.activation_code, password: "Third-Pass-3" }, realDeps());
    expect(second.status).toBe(401);
    expect(authUsers.get(parentLoginEmail(t.account_code))!.password).toBe("Another-Pass-2");
  });
  it("تخمين الرمز: 5 محاولات خاطئة تقفل حتى الرمز الصحيح عبر الخدمة", async () => {
    const t = await issue();
    for (let i = 0; i < 5; i++) {
      const r = await handleParentActivation({ account_code: t.account_code, activation_code: "0000-1111-2222-3333", password: "Whatever-Pass-9" }, realDeps());
      expect(r.status).toBe(401);
    }
    const locked = await handleParentActivation({ account_code: t.account_code, activation_code: t.activation_code, password: "Whatever-Pass-9" }, realDeps());
    expect(locked.status).toBe(401);
  });
  it("حساب محجوز مسبقاً بنفس البريد المشتق (squatting) لا يمنع التفعيل الحقيقي", async () => {
    const g2 = (await db.sql("INSERT INTO public.guardians (school_id, full_name, phone) SELECT school_id,'ولي جديد','+249911111111' FROM public.guardians LIMIT 1 RETURNING id"))[0].id;
    const t = (await db.tryAs({ kind: "user", id: principal }, "SELECT public.admin_issue_guardian_activation($1) AS r", [g2])).rows[0].r;
    const email = parentLoginEmail(t.account_code);
    const squatId = await db.newUser(email);
    authUsers.set(email, { id: squatId, guardian: false, password: "attacker" });
    const res = await handleParentActivation({ account_code: t.account_code, activation_code: t.activation_code, password: "Real-Parent-4" }, realDeps());
    expect(res.status).toBe(200);
    expect(authUsers.get(email)!.id).not.toBe(squatId);
    expect(authUsers.get(email)!.password).toBe("Real-Parent-4");
    expect((await dash(authUsers.get(email)!.id)).error).toBeUndefined();
  });
});
