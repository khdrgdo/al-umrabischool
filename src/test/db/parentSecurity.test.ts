// @vitest-environment node
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createDb, dbEnabled, type TestDb } from "./pg";

// اختبارات أمان حقيقية على PostgreSQL: RPCs وRLS والوصول المباشر.
const NEW_MIGRATION = "20261027000013_parent_auth_activation_and_owner_bootstrap.sql";

describe.skipIf(!dbEnabled)("أمان حسابات أولياء الأمور وصلاحية المالك (PostgreSQL حقيقي)", () => {
  let db: TestDb;
  let principal: string, teacher: string, parentA: string, parentB: string, stranger: string, parentSusp: string;
  let gA: string, gB: string, gS: string;

  beforeAll(async () => {
    db = await createDb();
    await db.seed();
    principal = await db.newUser("principal@school.test");
    teacher = await db.newUser("teacher@school.test");
    stranger = await db.newUser("stranger@public.test");
    parentA = await db.newUser("par-10101@parents.test");
    parentB = await db.newUser("par-20202@parents.test");
    parentSusp = await db.newUser("par-30303@parents.test");
    await db.sql("DELETE FROM public.user_roles");
    await db.sql("INSERT INTO public.user_roles (user_id, role) VALUES ($1,'principal'),($2,'supervisor')", [principal, teacher]);
    const g = async (code: string) => (await db.sql("SELECT id FROM public.guardians WHERE account_code=$1", [code]))[0].id as string;
    gA = await g("PAR-10101"); gB = await g("PAR-20202"); gS = await g("PAR-30303");
    await db.sql("UPDATE public.guardians SET user_id=$2 WHERE id=$1", [gA, parentA]);
    await db.sql("UPDATE public.guardians SET user_id=$2 WHERE id=$1", [gB, parentB]);
    await db.sql("UPDATE public.guardians SET user_id=$2 WHERE id=$1", [gS, parentSusp]);
  }, 120000);
  afterAll(async () => { await db?.close(); });

  const dash = async (uid: string) =>
    (await db.as({ kind: "user", id: uid }, async (c) => (await c.query("SELECT public.parent_get_dashboard_data() AS d")).rows[0].d)) as any;

  describe("P0-02/04: لا مصادقة بـ PIN عبر anon", () => {
    it("لا توجد دالة SECURITY DEFINER في public قابلة للتنفيذ من anon", async () => {
      const rows = await db.sql(`
        SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname='public' AND p.prosecdef AND p.prorettype <> 'trigger'::regtype
          AND has_function_privilege('anon', p.oid, 'EXECUTE')`);
      expect(rows.map((r) => r.proname)).toEqual([]);
    });
    it("parent_app_login و parent_get_portal_data لم تعودا موجودتين", async () => {
      const rows = await db.sql("SELECT proname FROM pg_proc WHERE proname IN ('parent_app_login','parent_get_portal_data')");
      expect(rows).toEqual([]);
    });
  });

  describe("P0-03: لا بيانات اعتماد نصية في أي مكان", () => {
    it("عمود temp_password_code محذوف", async () => {
      const rows = await db.sql("SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='guardians' AND (column_name ILIKE '%pass%' OR column_name ILIKE '%pin%')");
      expect(rows).toEqual([]);
    });
    it("الموظف (حتى المالك/المدير) لا يستطيع قراءة جدول رموز التفعيل", async () => {
      for (const uid of [principal, teacher]) {
        const r = await db.tryAs({ kind: "user", id: uid }, "SELECT * FROM public.guardian_activation_codes");
        expect(r.ok).toBe(false);
      }
    });
    it("anon لا يقرأ أي جدول أعمال", async () => {
      const tables = await db.sql("SELECT tablename FROM pg_tables WHERE schemaname='public'");
      for (const t of tables) {
        const r = await db.tryAs({ kind: "anon" }, `SELECT 1 FROM public."${t.tablename}" LIMIT 1`);
        expect(r.ok && r.rows.length > 0, `anon قرأ ${t.tablename}`).toBe(false);
      }
    });
    it("مستخدم مسجّل بلا دور لا يرى أي صف في أي جدول (عدا ملفه/أدواره)", async () => {
      const tables = await db.sql("SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename NOT IN ('profiles','user_roles')");
      for (const t of tables) {
        const r = await db.tryAs({ kind: "user", id: stranger }, `SELECT 1 FROM public."${t.tablename}" LIMIT 1`);
        expect(r.ok && r.rows.length > 0, `غريب قرأ ${t.tablename}`).toBe(false);
      }
    });
  });

  describe("عزل الأسر (RPC + وصول مباشر)", () => {
    const familyOf = async (gid: string) =>
      ((await db.sql("SELECT s.full_name FROM public.guardian_students gs JOIN public.students s ON s.id=gs.student_id WHERE gs.guardian_id=$1", [gid])) as any[])
        .map((r) => r.full_name as string).sort();
    it("ولي الأمر A يرى أبناءه فقط", async () => {
      const d = await dash(parentA);
      const names = d.children.map((c: any) => c.full_name).sort();
      expect(names.length).toBe(2);
      expect(names).toEqual(await familyOf(gA));
    });
    it("ولي الأمر B لا يرى أبناء A", async () => {
      const d = await dash(parentB);
      const names = d.children.map((c: any) => c.full_name).sort();
      expect(names).toEqual(await familyOf(gB));
      for (const n of await familyOf(gA)) expect(names).not.toContain(n);
    });
    it("مستخدم غير مرتبط بولي أمر → NOT_REGISTERED، والموقوف → ACCOUNT_SUSPENDED", async () => {
      expect((await dash(stranger)).error).toBe("NOT_REGISTERED");
      expect((await dash(parentSusp)).error).toBe("ACCOUNT_SUSPENDED");
    });
    it("ولي الأمر لا يقرأ الجداول مباشرة (طلاب/أولياء/مدفوعات/درجات)", async () => {
      for (const t of ["students", "guardians", "guardian_students", "student_payments", "student_grades", "enrollments"]) {
        const r = await db.tryAs({ kind: "user", id: parentA }, `SELECT 1 FROM public.${t} LIMIT 1`);
        expect(r.ok && r.rows.length > 0, `ولي الأمر قرأ ${t}`).toBe(false);
      }
    });
    it("ولي الأمر لا يستطيع ربط نفسه بطالب ولا تعديل سجله", async () => {
      const st = (await db.sql("SELECT student_id AS id FROM public.guardian_students WHERE guardian_id=$1 LIMIT 1", [gB]))[0].id;
      const ins = await db.tryAs({ kind: "user", id: parentA }, "INSERT INTO public.guardian_students (guardian_id, student_id) VALUES ($1,$2)", [gA, st]);
      expect(ins.ok).toBe(false);
      const upd = await db.tryAs({ kind: "user", id: parentA }, "UPDATE public.guardians SET status='active', user_id=$2 WHERE id=$1 RETURNING id", [gB, parentA]);
      expect(upd.ok && upd.rows.length > 0).toBe(false);
    });
    it("المعلم (supervisor) لا يستطيع ربط طالب بولي أمر", async () => {
      const st = (await db.sql("SELECT student_id AS id FROM public.guardian_students WHERE guardian_id=$1 LIMIT 1", [gB]))[0].id;
      const ins = await db.tryAs({ kind: "user", id: teacher }, "INSERT INTO public.guardian_students (guardian_id, student_id) VALUES ($1,$2)", [gA, st]);
      expect(ins.ok).toBe(false);
    });
  });

  describe("P0-02: مسار التفعيل (رمز لمرة واحدة، hash، انتهاء، حد محاولات)", () => {
    const issue = async (uid: string, gid: string, fn = "admin_issue_guardian_activation") =>
      db.tryAs({ kind: "user", id: uid }, `SELECT public.${fn}($1) AS r`, [gid]);
    const check = async (code: string, plain: string) =>
      db.tryAs({ kind: "service" }, "SELECT public.parent_check_activation($1,$2) AS r", [code, plain]);

    it("الموظف غير المدير لا يستطيع إصدار رمز تفعيل أو إعادة تعيين", async () => {
      expect((await issue(teacher, gB)).ok).toBe(false);
      expect((await issue(teacher, gB, "admin_reset_guardian_password")).ok).toBe(false);
      expect((await issue(stranger, gB)).ok).toBe(false);
    });
    it("المدير يصدر رمزاً؛ يُخزَّن hash فقط ولا يظهر النص في أي جدول أو سجل تدقيق", async () => {
      const r = await issue(principal, gB);
      expect(r.ok, r.error).toBe(true);
      const out = r.rows[0].r;
      expect(out.activation_code).toMatch(/^[0-9A-F]{4}(-[0-9A-F]{4}){3}$/);
      const code: string = out.activation_code;
      const stored = (await db.sql("SELECT code_hash FROM public.guardian_activation_codes WHERE guardian_id=$1", [gB]))[0].code_hash as string;
      expect(stored).not.toContain(code.replace(/-/g, ""));
      expect(stored).not.toContain(code);
      const leaks = await db.sql(`SELECT
        (SELECT count(*) FROM public.audit_log WHERE new_data::text ILIKE '%'||$1||'%' OR old_data::text ILIKE '%'||$1||'%')::int AS audit,
        (SELECT count(*) FROM public.guardians g WHERE row_to_json(g)::text ILIKE '%'||$1||'%')::int AS g`, [code.replace(/-/g, "")]);
      expect(leaks[0]).toEqual({ audit: 0, g: 0 });
    });
    it("الاستدعاء من authenticated/anon لدوال التحقق مرفوض (service_role فقط)", async () => {
      for (const a of [{ kind: "anon" as const }, { kind: "user" as const, id: principal }]) {
        const r = await db.tryAs(a, "SELECT public.parent_check_activation('PAR-20202','x')");
        expect(r.ok).toBe(false);
        const r2 = await db.tryAs(a, "SELECT public.parent_complete_activation($1,$2)", [gB, principal]);
        expect(r2.ok).toBe(false);
      }
    });
    it("رمز خاطئ/حساب غير موجود يعطيان نفس النتيجة العامة (null)", async () => {
      const issued = (await issue(principal, gB)).rows[0].r;
      expect((await check("PAR-20202", "0000-0000-0000-0000")).rows[0].r).toBeNull();
      expect((await check("PAR-NOPE99", issued.activation_code)).rows[0].r).toBeNull();
    });
    it("قفل بعد 5 محاولات خاطئة حتى مع الرمز الصحيح، وإعادة الإصدار تفتحه", async () => {
      const issued = (await issue(principal, gB)).rows[0].r;
      for (let i = 0; i < 5; i++) await check("PAR-20202", "FFFF-FFFF-FFFF-FFFF");
      expect((await check("PAR-20202", issued.activation_code)).rows[0].r).toBeNull();
      const again = (await issue(principal, gB)).rows[0].r;
      expect((await check("PAR-20202", again.activation_code)).rows[0].r).not.toBeNull();
    });
    it("الرمز المنتهي مرفوض", async () => {
      const issued = (await issue(principal, gB)).rows[0].r;
      await db.sql("UPDATE public.guardian_activation_codes SET expires_at = now() - interval '1 minute' WHERE guardian_id=$1", [gB]);
      expect((await check("PAR-20202", issued.activation_code)).rows[0].r).toBeNull();
    });
    it("التفعيل الناجح: يُربط user_id، الحالة active، والرمز لا يُستخدم مرتين", async () => {
      const newGuardian = (await db.sql(
        "INSERT INTO public.guardians (school_id, full_name, phone) SELECT school_id,'ولي جديد','+249900000001' FROM public.guardians LIMIT 1 RETURNING id"))[0].id as string;
      const issued = (await issue(principal, newGuardian)).rows[0].r;
      const acct: string = issued.account_code;
      const chk = (await check(acct, issued.activation_code)).rows[0].r;
      expect(chk.guardian_id).toBe(newGuardian);
      expect(chk.purpose).toBe("activate");
      const uid = await db.newUser("new-guardian@parents.test");
      const done = await db.tryAs({ kind: "service" }, "SELECT public.parent_complete_activation($1,$2) AS r", [newGuardian, uid]);
      expect(done.rows[0].r).toBe(true);
      const row = (await db.sql("SELECT user_id, status FROM public.guardians WHERE id=$1", [newGuardian]))[0];
      expect(row).toEqual({ user_id: uid, status: "active" });
      expect((await check(acct, issued.activation_code)).rows[0].r).toBeNull();
      const twice = await db.tryAs({ kind: "service" }, "SELECT public.parent_complete_activation($1,$2) AS r", [newGuardian, uid]);
      expect(twice.rows[0].r).toBe(false);
    });
    it("إعادة تعيين كلمة المرور لحساب مرتبط تعطي purpose=reset ولا تغيّر الارتباط", async () => {
      const r = await issue(principal, gA, "admin_reset_guardian_password");
      expect(r.ok, r.error).toBe(true);
      const chk = (await check("PAR-10101", r.rows[0].r.activation_code)).rows[0].r;
      expect(chk.purpose).toBe("reset");
      expect(chk.user_id).toBe(parentA);
    });
    it("الحساب الموقوف لا يُفعَّل ولا يُعاد تعيينه بالرمز", async () => {
      const r = await issue(principal, gS);
      expect(r.ok).toBe(false);
    });
  });

  describe("P0-05: صلاحية المالك", () => {
    it("التسجيل العام لا يمنح أي دور (حتى لو كان أول مستخدم)", async () => {
      const fresh = await createDb();
      try {
        const uid = await fresh.newUser("first@public.test");
        expect(await fresh.sql("SELECT role FROM public.user_roles WHERE user_id=$1", [uid])).toEqual([]);
        expect((await fresh.sql("SELECT id FROM public.profiles WHERE id=$1", [uid])).length).toBe(1);
      } finally { await fresh.close(); }
    });
    it("bootstrap_first_owner: service_role فقط، يمنح owner لمرة واحدة، ويرفض بعدها", async () => {
      const fresh = await createDb();
      try {
        const uid = await fresh.newUser("owner@school.test");
        const other = await fresh.newUser("other@school.test");
        for (const a of [{ kind: "anon" as const }, { kind: "user" as const, id: uid }]) {
          expect((await fresh.tryAs(a, "SELECT public.bootstrap_first_owner('owner@school.test')")).ok).toBe(false);
        }
        const ok = await fresh.tryAs({ kind: "service" }, "SELECT public.bootstrap_first_owner('owner@school.test') AS r");
        expect(ok.ok, ok.error).toBe(true);
        expect((await fresh.sql("SELECT role FROM public.user_roles WHERE user_id=$1", [uid]))[0].role).toBe("owner");
        expect((await fresh.tryAs({ kind: "service" }, "SELECT public.bootstrap_first_owner('other@school.test')")).ok).toBe(false);
        expect(await fresh.sql("SELECT 1 FROM public.user_roles WHERE user_id=$1", [other])).toEqual([]);
      } finally { await fresh.close(); }
    });
    it("غير المالك لا يستطيع منح نفسه دوراً عبر user_roles", async () => {
      for (const uid of [stranger, teacher, principal]) {
        const r = await db.tryAs({ kind: "user", id: uid }, "INSERT INTO public.user_roles (user_id, role) VALUES ($1,'owner')", [uid]);
        expect(r.ok, `${uid} منح نفسه owner`).toBe(false);
      }
    });
  });

  describe("الترحيل من الحسابات القديمة (PIN نصي) دون كسرها", () => {
    it("حساب قديم برمزه القديم يُفعَّل بعد الترحيل، ولا يبقى النص الصريح", async () => {
      const old = await createDb({ upTo: "20261026000012~" });
      try {
        await old.seed();
        await old.sql("UPDATE public.guardians SET temp_password_code='449210' WHERE account_code='PAR-10101'");
        await old.sql("UPDATE public.guardians SET temp_password_code='998877' WHERE account_code='PAR-30303'");
        expect((await old.sql("SELECT temp_password_code AS p FROM public.guardians WHERE account_code='PAR-10101'"))[0].p).toBe("449210");
        await old.applyMigration(NEW_MIGRATION);
        const chk = (await old.tryAs({ kind: "service" }, "SELECT public.parent_check_activation('PAR-10101','449210') AS r")).rows[0].r;
        expect(chk?.purpose).toBe("activate");
        expect((await old.tryAs({ kind: "service" }, "SELECT public.parent_check_activation('PAR-10101','000000') AS r")).rows[0].r).toBeNull();
        expect(await old.sql("SELECT 1 FROM information_schema.columns WHERE table_name='guardians' AND column_name='temp_password_code'")).toEqual([]);
        const leak = await old.sql("SELECT count(*)::int c FROM public.audit_log WHERE new_data::text LIKE '%449210%' OR old_data::text LIKE '%449210%'");
        expect(leak[0].c).toBe(0);
      } finally { await old.close(); }
    }, 60000);
    it("الحساب الموقوف قبل الترحيل لا يُحوَّل رمزه القديم إلى رمز تفعيل", async () => {
      const old = await createDb({ upTo: "20261026000012~" });
      try {
        await old.seed();
        await old.sql("UPDATE public.guardians SET temp_password_code='998877' WHERE account_code='PAR-30303'");
        await old.applyMigration(NEW_MIGRATION);
        const r = await old.tryAs({ kind: "service" }, "SELECT public.parent_check_activation('PAR-30303','998877') AS r");
        expect(r.rows[0].r).toBeNull();
      } finally { await old.close(); }
    }, 60000);
  });

  describe("قيود إضافية: الأعمدة الحساسة، الإيقاف/إعادة التفعيل، ختم التحقق", () => {
    it("حتى المدير لا يضبط user_id أو status أو account_code مباشرة؛ ويعدّل البيانات الشخصية فقط", async () => {
      const P = { kind: "user" as const, id: principal };
      for (const col of ["user_id = $2", "status = 'active'", "account_code = 'PAR-HACK01'"]) {
        const r = await db.tryAs(P, `UPDATE public.guardians SET ${col} WHERE id = $1`, col.startsWith("user_id") ? [gB, stranger] : [gB]);
        expect(r.ok, `UPDATE ${col} يجب أن يُرفض`).toBe(false);
      }
      expect((await db.tryAs(P, "UPDATE public.guardians SET full_name = full_name WHERE id = $1", [gB])).ok).toBe(true);
      const ins = await db.tryAs(P, "INSERT INTO public.guardians (school_id, full_name, phone, status) SELECT school_id,'x','1','active' FROM public.guardians LIMIT 1");
      expect(ins.ok).toBe(false);
    });
    it("دوال الإدارة مرفوضة لـ anon، وإيقاف الحساب يقطع الوصول، وإعادة التفعيل تعيده دون تغيير كلمة المرور", async () => {
      expect((await db.tryAs({ kind: "anon" }, "SELECT public.admin_suspend_guardian_account($1,'x')", [gA])).ok).toBe(false);
      const P = { kind: "user" as const, id: principal };
      expect((await db.tryAs(P, "SELECT public.admin_suspend_guardian_account($1,'اختبار')", [gA])).ok).toBe(true);
      expect((await dash(parentA)).error).toBe("ACCOUNT_SUSPENDED");
      expect((await db.tryAs(P, "SELECT public.admin_issue_guardian_activation($1)", [gA])).ok).toBe(false);
      const re = await db.tryAs(P, "SELECT public.admin_activate_guardian_account($1) AS r", [gA]);
      expect(re.rows[0].r.status).toBe("active");
      expect(re.rows[0].r.activation_code).toBeUndefined();
      expect((await dash(parentA)).error).toBeUndefined();
    });
    it("ربط طالب بولي أمر عبر المدير يختم verified_by باسمه", async () => {
      const st = (await db.sql("SELECT student_id AS id FROM public.guardian_students WHERE guardian_id=$1 LIMIT 1", [gB]))[0].id;
      await db.sql("DELETE FROM public.guardian_students WHERE guardian_id=$1 AND student_id=$2", [gA, st]);
      const r = await db.tryAs({ kind: "user", id: principal }, "INSERT INTO public.guardian_students (guardian_id, student_id) VALUES ($1,$2) RETURNING verified_by", [gA, st]);
      expect(r.ok, r.error).toBe(true);
      expect(r.rows[0].verified_by).toBe(principal);
    });
  });
});
